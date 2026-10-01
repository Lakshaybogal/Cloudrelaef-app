import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

import 'http_util.dart';
import 'storage_provider.dart';

const _authUrl = 'https://www.dropbox.com/oauth2/authorize';
const _tokenUrl = 'https://api.dropboxapi.com/oauth2/token';
const _rpc = 'https://api.dropboxapi.com/2';
const _content = 'https://content.dropboxapi.com/2';

/// Multiple of 4 MiB, as Dropbox recommends.
const dropboxChunkSize = 8 * 1024 * 1024;

const dropboxDefaultScopes =
    'files.metadata.read files.metadata.write files.content.read '
    'files.content.write account_info.read';

/// Dropbox "App folder" access: the app folder is the root ("") for the API.
class DropboxProvider implements StorageProvider {
  DropboxProvider(
    this.config, {
    http.Client? client,
    this.scopes = dropboxDefaultScopes,
    DateTime Function()? now,
  }) : _http = client ?? http.Client(),
       _now = now ?? DateTime.now;

  final OAuthClientConfig config;
  final String scopes;
  final http.Client _http;
  final DateTime Function() _now;

  @override
  String get id => 'dropbox';
  @override
  String get displayName => 'Dropbox';

  Map<String, String> _bearer(AccessToken a) => {
    'Authorization': 'Bearer ${a.token}',
  };

  /// Header args must be ASCII, so non-ASCII characters are \u-escaped.
  String _arg(Map<String, dynamic> data) {
    final sb = StringBuffer();
    for (final unit in jsonEncode(data).codeUnits) {
      if (unit < 128) {
        sb.writeCharCode(unit);
      } else {
        sb.write('\\u${unit.toRadixString(16).padLeft(4, '0')}');
      }
    }
    return sb.toString();
  }

  @override
  Uri authUrl({
    required String state,
    required String redirectUri,
    required String codeChallenge,
  }) => Uri.parse(_authUrl).replace(
    queryParameters: {
      'client_id': config.clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'token_access_type': 'offline', // yields a refresh token
      'scope': scopes,
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
      var error = '';
      try {
        error = (jsonDecode(r.body) as Map)['error'] as String? ?? '';
      } catch (_) {}
      if (error == 'invalid_grant') {
        throw ReauthRequired(
          'Dropbox refresh token or code is no longer valid',
          status: 400,
        );
      }
      throw ProviderError(
        'Dropbox token request rejected (${error.isEmpty ? r.statusCode : error})',
        status: 400,
      );
    }
    checkOk(r, 'Dropbox', 'token request');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  AccessToken _access(Map<String, dynamic> b) => AccessToken(
    token: b['access_token'] as String,
    expiresAt: _now().add(
      Duration(seconds: (b['expires_in'] as num?)?.toInt() ?? 14400),
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
        'Dropbox returned no refresh token; check the app allows offline access',
      );
    }
    final access = _access(body);
    final r = await sendWithRetry(
      () => _http.post(
        Uri.parse('$_rpc/users/get_current_account'),
        headers: _bearer(access),
      ),
    );
    checkOk(r, 'Dropbox', 'account lookup');
    final acct = jsonDecode(r.body) as Map<String, dynamic>;
    return TokenSet(
      refreshToken: refresh,
      access: access,
      accountId: acct['account_id'] as String,
      displayName:
          (acct['email'] ??
                  (acct['name'] as Map?)?['display_name'] ??
                  'Dropbox')
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

  Future<http.Response> _rpcCall(
    AccessToken a,
    String endpoint, [
    Map<String, dynamic>? body,
  ]) => sendWithRetry(
    () => _http.post(
      Uri.parse('$_rpc/$endpoint'),
      headers: {
        ..._bearer(a),
        if (body != null) 'Content-Type': 'application/json',
      },
      body: body == null ? null : jsonEncode(body),
    ),
  );

  @override
  Future<Quota> getQuota(AccessToken access) async {
    final r = await _rpcCall(access, 'users/get_space_usage');
    checkOk(r, 'Dropbox', 'quota');
    final b = jsonDecode(r.body) as Map<String, dynamic>;
    final allocated = (b['allocation'] as Map?)?['allocated'];
    return Quota(
      total: allocated == null || allocated == 0
          ? null
          : (allocated as num).toInt(),
      used: ((b['used'] ?? 0) as num).toInt(),
    );
  }

  RemoteFile _toRemote(Map<String, dynamic> f) {
    final name = f['name'] as String;
    return RemoteFile(
      remoteId: f['id'] as String, // "id:..." works wherever a path does
      name: name,
      size: ((f['size'] ?? 0) as num).toInt(),
      mime: lookupMimeType(name) ?? 'application/octet-stream',
      hash: f['content_hash'] as String?,
      modifiedAt: DateTime.parse(
        (f['server_modified'] as String?) ?? '1970-01-01T00:00:00Z',
      ),
      path: (f['path_display'] as String?) ?? '/$name',
    );
  }

  @override
  Future<FilePage> listFiles(AccessToken access, {String? cursor}) async {
    final r = cursor != null
        ? await _rpcCall(access, 'files/list_folder/continue', {
            'cursor': cursor,
          })
        : await _rpcCall(access, 'files/list_folder', {
            'path': '',
            'recursive': true,
            'include_deleted': false,
            'limit': 2000,
          });
    checkOk(r, 'Dropbox', 'list');
    final b = jsonDecode(r.body) as Map<String, dynamic>;
    return FilePage(
      files: [
        for (final e in (b['entries'] as List? ?? []))
          if ((e as Map)['.tag'] == 'file')
            _toRemote(e.cast<String, dynamic>()),
      ],
      nextCursor: b['has_more'] == true ? b['cursor'] as String : null,
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
    final commit = {
      'path': '/$name',
      'mode': 'add',
      'autorename': true,
      'mute': false,
    };

    Future<http.Response> send(
      String endpoint,
      Map<String, dynamic> arg,
      List<int> bytes,
    ) async {
      final r = await sendWithRetry(
        () => _http.post(
          Uri.parse('$_content/files/$endpoint'),
          headers: {
            ..._bearer(access),
            'Content-Type': 'application/octet-stream',
            'Dropbox-API-Arg': _arg(arg),
          },
          body: bytes,
        ),
      );
      checkOk(r, 'Dropbox', 'upload');
      return r;
    }

    var sent = 0;
    var buf = <int>[];
    String? sessionId;
    await for (final piece in data) {
      buf.addAll(piece);
      if (sent + buf.length > size) {
        throw ProviderError('Upload body is larger than the declared size');
      }
      // Send full chunks but always keep the final chunk back for `finish`.
      while (size > dropboxChunkSize &&
          buf.length >= dropboxChunkSize &&
          sent + dropboxChunkSize < size) {
        final chunk = buf.sublist(0, dropboxChunkSize);
        buf = buf.sublist(dropboxChunkSize);
        if (sessionId == null) {
          final r = await send('upload_session/start', {'close': false}, chunk);
          sessionId = (jsonDecode(r.body) as Map)['session_id'] as String;
        } else {
          await send('upload_session/append_v2', {
            'cursor': {'session_id': sessionId, 'offset': sent},
            'close': false,
          }, chunk);
        }
        sent += chunk.length;
      }
    }
    if (sent + buf.length != size) {
      throw ProviderError('Upload ended before all bytes were sent');
    }
    final r = sessionId == null
        ? await send('upload', commit, buf)
        : await send('upload_session/finish', {
            'cursor': {'session_id': sessionId, 'offset': sent},
            'commit': commit,
          }, buf);
    return _toRemote(jsonDecode(r.body) as Map<String, dynamic>);
  }

  @override
  Stream<List<int>> download(AccessToken access, String remoteId) async* {
    final req = http.Request('POST', Uri.parse('$_content/files/download'))
      ..headers.addAll({
        ..._bearer(access),
        'Dropbox-API-Arg': _arg({'path': remoteId}),
      });
    final resp = await _http.send(req);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      await resp.stream.drain<void>();
      throw ProviderError(
        'Dropbox download failed (${resp.statusCode})',
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
    final meta = await _rpcCall(access, 'files/get_metadata', {
      'path': remoteId,
    });
    checkOk(meta, 'Dropbox', 'file lookup');
    final current =
        ((jsonDecode(meta.body) as Map)['path_display'] as String?) ?? '';
    final parent = current.contains('/')
        ? current.substring(0, current.lastIndexOf('/'))
        : '';
    final r = await _rpcCall(access, 'files/move_v2', {
      'from_path': remoteId,
      'to_path': '$parent/$newName',
      'autorename': false,
    });
    if (r.statusCode == 409 && r.body.contains('conflict')) {
      throw ProviderError(
        'A file with that name already exists in this folder',
        status: 409,
      );
    }
    checkOk(r, 'Dropbox', 'rename');
    return _toRemote(
      ((jsonDecode(r.body) as Map)['metadata'] as Map).cast<String, dynamic>(),
    );
  }

  @override
  Future<void> delete(AccessToken access, String remoteId) async {
    final r = await _rpcCall(access, 'files/delete_v2', {'path': remoteId});
    if (r.statusCode == 409 && r.body.contains('not_found')) return;
    checkOk(r, 'Dropbox', 'delete');
  }
}
