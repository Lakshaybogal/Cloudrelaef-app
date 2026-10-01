import 'dart:convert';

import 'package:http/http.dart' as http;

import 'http_util.dart';
import 'storage_provider.dart';

const _authUrl = 'https://accounts.google.com/o/oauth2/v2/auth';
const _tokenUrl = 'https://oauth2.googleapis.com/token';
const _api = 'https://www.googleapis.com/drive/v3';
const _uploadUrl = 'https://www.googleapis.com/upload/drive/v3/files';
const _fileFields = 'id,name,size,mimeType,md5Checksum,modifiedTime';
const _folderMime = 'application/vnd.google-apps.folder';

/// Resumable-upload chunks must be a multiple of 256 KiB.
const googleChunkSize = 8 * 1024 * 1024;

/// Default scope sees only files the app creates or the user picks. With your
/// own OAuth app you may widen it to `https://www.googleapis.com/auth/drive`.
const googleDefaultScope = 'https://www.googleapis.com/auth/drive.file';

class GoogleDriveProvider implements StorageProvider {
  GoogleDriveProvider(
    this.config, {
    http.Client? client,
    this.scope = googleDefaultScope,
    DateTime Function()? now,
  }) : _http = client ?? http.Client(),
       _now = now ?? DateTime.now;

  final OAuthClientConfig config;
  final String scope;
  final http.Client _http;
  final DateTime Function() _now;

  @override
  String get id => 'google';
  @override
  String get displayName => 'Google Drive';

  Map<String, String> _bearer(AccessToken a) => {
    'Authorization': 'Bearer ${a.token}',
  };

  @override
  Uri authUrl({
    required String state,
    required String redirectUri,
    required String codeChallenge,
  }) => Uri.parse(_authUrl).replace(
    queryParameters: {
      'client_id': config.clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': scope,
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      // Without these Google returns no refresh token on reconnects.
      'access_type': 'offline',
      'prompt': 'consent',
    },
  );

  Future<Map<String, dynamic>> _tokenRequest(Map<String, String> data) async {
    final body = {
      ...data,
      'client_id': config.clientId,
      if (config.clientSecret != null) 'client_secret': config.clientSecret!,
    };
    final r = await sendWithRetry(
      () => _http.post(Uri.parse(_tokenUrl), body: body),
    );
    if (r.statusCode == 400 || r.statusCode == 401) {
      String error = '';
      try {
        error = (jsonDecode(r.body) as Map)['error'] as String? ?? '';
      } catch (_) {}
      if (error == 'invalid_grant') {
        throw ReauthRequired(
          'Google refresh token or code is no longer valid',
          status: 400,
        );
      }
      throw ProviderError(
        'Google token request rejected (${error.isEmpty ? r.statusCode : error})',
        status: 400,
      );
    }
    checkOk(r, 'Google', 'token request');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  AccessToken _access(Map<String, dynamic> body) => AccessToken(
    token: body['access_token'] as String,
    expiresAt: _now().add(
      Duration(seconds: (body['expires_in'] as num?)?.toInt() ?? 3600),
    ),
  );

  @override
  Future<TokenSet> exchangeCode({
    required String code,
    required String redirectUri,
    required String verifier,
  }) async {
    final body = await _tokenRequest({
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': redirectUri,
      'code_verifier': verifier,
    });
    final refresh = body['refresh_token'] as String?;
    if (refresh == null) {
      throw ProviderError(
        'Google returned no refresh token; revoke CloudRelaef in your Google '
        'account and retry',
      );
    }
    final access = _access(body);
    final r = await sendWithRetry(
      () => _http.get(
        Uri.parse('$_api/about').replace(
          queryParameters: {
            'fields': 'user(emailAddress,permissionId,displayName)',
          },
        ),
        headers: _bearer(access),
      ),
    );
    checkOk(r, 'Google Drive', 'account lookup');
    final user = (jsonDecode(r.body) as Map)['user'] as Map<String, dynamic>;
    return TokenSet(
      refreshToken: refresh,
      access: access,
      accountId: user['permissionId'] as String,
      displayName:
          (user['emailAddress'] ?? user['displayName'] ?? 'Google Drive')
              as String,
    );
  }

  @override
  Future<AccessToken> refreshToken(String refreshToken) async => _access(
    await _tokenRequest({
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
    }),
  );

  @override
  Future<Quota> getQuota(AccessToken access) async {
    final r = await sendWithRetry(
      () => _http.get(
        Uri.parse('$_api/about')
            .replace(queryParameters: {'fields': 'storageQuota'}),
        headers: _bearer(access),
      ),
    );
    checkOk(r, 'Google Drive', 'quota');
    final q = (jsonDecode(r.body) as Map)['storageQuota'] as Map;
    final limit = q['limit'];
    return Quota(
      total: limit == null ? null : int.parse('$limit'),
      used: int.parse('${q['usage'] ?? 0}'),
    );
  }

  RemoteFile _toRemote(Map<String, dynamic> f) => RemoteFile(
    remoteId: f['id'] as String,
    name: f['name'] as String,
    size: int.parse('${f['size'] ?? 0}'),
    mime: (f['mimeType'] as String?) ?? 'application/octet-stream',
    hash: f['md5Checksum'] as String?,
    modifiedAt: DateTime.parse(f['modifiedTime'] as String),
    path: '/${f['name']}',
  );

  @override
  Future<FilePage> listFiles(AccessToken access, {String? cursor}) async {
    final r = await sendWithRetry(
      () => _http.get(
        Uri.parse('$_api/files').replace(
          queryParameters: {
            'q': "trashed = false and mimeType != '$_folderMime'",
            'fields': 'nextPageToken,files($_fileFields)',
            'pageSize': '1000',
            'pageToken': ?cursor,
          },
        ),
        headers: _bearer(access),
      ),
    );
    checkOk(r, 'Google Drive', 'list');
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return FilePage(
      files: [
        for (final f in (body['files'] as List? ?? []))
          _toRemote(f as Map<String, dynamic>),
      ],
      nextCursor: body['nextPageToken'] as String?,
    );
  }

  @override
  Future<RemoteFile> upload(
    AccessToken access, {
    required String name,
    required int size,
    required String mime,
    required Stream<List<int>> data,
  }) async {
    final init = await sendWithRetry(
      () => _http.post(
        Uri.parse(_uploadUrl).replace(
          queryParameters: {'uploadType': 'resumable', 'fields': _fileFields},
        ),
        headers: {
          ..._bearer(access),
          'Content-Type': 'application/json; charset=UTF-8',
          'X-Upload-Content-Type': mime,
          'X-Upload-Content-Length': '$size',
        },
        body: jsonEncode({'name': name}),
      ),
    );
    checkOk(init, 'Google Drive', 'upload start');
    final session = init.headers['location'];
    if (session == null) {
      throw ProviderError('Google Drive upload start returned no session');
    }

    Future<http.Response> put(List<int> chunk, int start) async {
      final range = chunk.isEmpty
          ? 'bytes */$size'
          : 'bytes $start-${start + chunk.length - 1}/$size';
      final r = await sendWithRetry(
        () => _http.put(
          Uri.parse(session),
          headers: {'Content-Range': range},
          body: chunk,
        ),
      );
      if (r.statusCode != 200 && r.statusCode != 201 && r.statusCode != 308) {
        checkOk(r, 'Google Drive', 'upload chunk');
      }
      return r;
    }

    var sent = 0;
    var buf = <int>[];
    http.Response? last;
    if (size == 0) last = await put(const [], 0);
    await for (final piece in data) {
      buf.addAll(piece);
      if (sent + buf.length > size) {
        throw ProviderError('Upload body is larger than the declared size');
      }
      while (buf.length >= googleChunkSize) {
        final chunk = buf.sublist(0, googleChunkSize);
        buf = buf.sublist(googleChunkSize);
        last = await put(chunk, sent);
        sent += chunk.length;
      }
    }
    if (buf.isNotEmpty) {
      last = await put(buf, sent);
      sent += buf.length;
    }
    if (sent != size ||
        last == null ||
        (last.statusCode != 200 && last.statusCode != 201)) {
      throw ProviderError('Upload ended before all bytes were sent');
    }
    return _toRemote(jsonDecode(last.body) as Map<String, dynamic>);
  }

  @override
  Stream<List<int>> download(AccessToken access, String remoteId) async* {
    final req = http.Request(
      'GET',
      Uri.parse('$_api/files/$remoteId')
          .replace(queryParameters: {'alt': 'media'}),
    )..headers.addAll(_bearer(access));
    final resp = await _http.send(req);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      await resp.stream.drain<void>();
      throw ProviderError(
        'Google Drive download failed (${resp.statusCode})',
        status: resp.statusCode,
      );
    }
    yield* resp.stream;
  }

  @override
  Future<RemoteFile> rename(
    AccessToken access,
    String remoteId,
    String newName,
  ) async {
    final r = await sendWithRetry(
      () => _http.patch(
        Uri.parse('$_api/files/$remoteId')
            .replace(queryParameters: {'fields': _fileFields}),
        headers: {
          ..._bearer(access),
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({'name': newName}),
      ),
    );
    if (r.statusCode == 404) {
      throw ProviderError(
        'File not found or not shared with CloudRelaef',
        status: 404,
      );
    }
    checkOk(r, 'Google Drive', 'rename');
    return _toRemote(jsonDecode(r.body) as Map<String, dynamic>);
  }

  @override
  Future<void> delete(AccessToken access, String remoteId) async {
    final r = await sendWithRetry(
      () => _http.delete(
        Uri.parse('$_api/files/$remoteId'),
        headers: _bearer(access),
      ),
    );
    if (r.statusCode == 404) return; // already gone
    checkOk(r, 'Google Drive', 'delete');
  }
}
