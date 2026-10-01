import 'dart:convert';

import 'package:http/http.dart' as http;

import 'http_util.dart';
import 'storage_provider.dart';

const _authUrl =
    'https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize';
const _tokenUrl =
    'https://login.microsoftonline.com/consumers/oauth2/v2.0/token';
const _graph = 'https://graph.microsoft.com/v1.0';
const _approot = '$_graph/me/drive/special/approot';
const _select =
    'id,name,size,file,deleted,lastModifiedDateTime,parentReference';

/// Must be a multiple of 320 KiB (327,680).
const onedriveChunkSize = 10 * 1024 * 1024;

const onedriveDefaultScopes =
    'Files.ReadWrite.AppFolder offline_access User.Read';

final _invalidName = RegExp(r'[\\/:*?"<>|]'); // forbidden by OneDrive

/// Personal OneDrive through Microsoft Graph, app-folder scope. Files live in
/// `OneDrive/Apps/<app name>/`.
class OneDriveProvider implements StorageProvider {
  OneDriveProvider(
    this.config, {
    http.Client? client,
    this.scopes = onedriveDefaultScopes,
    DateTime Function()? now,
  }) : _http = client ?? http.Client(),
       _now = now ?? DateTime.now;

  final OAuthClientConfig config;
  final String scopes;
  final http.Client _http;
  final DateTime Function() _now;

  @override
  String get id => 'onedrive';
  @override
  String get displayName => 'OneDrive';

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
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'response_mode': 'query',
      'scope': scopes, // offline_access is what yields a refresh token
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'prompt': 'select_account',
    },
  );

  Future<Map<String, dynamic>> _tokenRequest(Map<String, String> data) async {
    final body = {
      ...data,
      'client_id': config.clientId,
      'scope': scopes,
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
      if (error == 'invalid_grant' || error == 'interaction_required') {
        throw ReauthRequired(
          'Microsoft refresh token or code is no longer valid',
          status: 400,
        );
      }
      throw ProviderError(
        'Microsoft token request rejected (${error.isEmpty ? r.statusCode : error})',
        status: 400,
      );
    }
    checkOk(r, 'OneDrive', 'token request');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  /// Microsoft rotates refresh tokens: every refresh returns a new one.
  AccessToken _access(Map<String, dynamic> b) => AccessToken(
    token: b['access_token'] as String,
    expiresAt: _now().add(
      Duration(seconds: (b['expires_in'] as num?)?.toInt() ?? 3600),
    ),
    newRefreshToken: b['refresh_token'] as String?,
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
        'Microsoft returned no refresh token; check the offline_access permission',
      );
    }
    final access = _access(body);
    final r = await sendWithRetry(
      () => _http.get(Uri.parse('$_graph/me'), headers: _bearer(access)),
    );
    checkOk(r, 'OneDrive', 'account lookup');
    final me = jsonDecode(r.body) as Map<String, dynamic>;
    return TokenSet(
      refreshToken: refresh,
      access: access,
      accountId: me['id'] as String,
      displayName:
          (me['mail'] ??
                  me['userPrincipalName'] ??
                  me['displayName'] ??
                  'OneDrive')
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

  /// With only the app-folder scope Graph may refuse the quota (403, seen once
  /// right after first consent). Throws [ProviderError]; callers estimate.
  @override
  Future<Quota> getQuota(AccessToken access) async {
    final r = await sendWithRetry(
      () => _http.get(
        Uri.parse('$_graph/me/drive')
            .replace(queryParameters: {r'$select': 'quota'}),
        headers: _bearer(access),
      ),
    );
    checkOk(r, 'OneDrive', 'quota');
    final q = ((jsonDecode(r.body) as Map)['quota'] as Map?) ?? const {};
    final total = q['total'];
    return Quota(
      total: total == null || total == 0 ? null : (total as num).toInt(),
      used: ((q['used'] ?? 0) as num).toInt(),
    );
  }

  RemoteFile _toRemote(Map<String, dynamic> f) {
    final parent = ((f['parentReference'] as Map?)?['path'] as String?) ?? '';
    final folder = parent.contains(':')
        ? parent.split(':').sublist(1).join(':')
        : '';
    final file = (f['file'] as Map?) ?? const {};
    final hashes = (file['hashes'] as Map?) ?? const {};
    return RemoteFile(
      remoteId: f['id'] as String,
      name: f['name'] as String,
      size: ((f['size'] ?? 0) as num).toInt(),
      mime: (file['mimeType'] as String?) ?? 'application/octet-stream',
      hash: (hashes['sha1Hash'] ?? hashes['quickXorHash']) as String?,
      modifiedAt: DateTime.parse(
        (f['lastModifiedDateTime'] as String?) ?? '1970-01-01T00:00:00Z',
      ),
      path: '$folder/${f['name']}',
    );
  }

  /// Lists the app folder recursively through the delta endpoint (Graph has
  /// no recursive list). The cursor is the `@odata.nextLink`.
  @override
  Future<FilePage> listFiles(AccessToken access, {String? cursor}) async {
    if (cursor != null && !cursor.startsWith(_graph)) {
      throw ProviderError('Invalid listing cursor');
    }
    final url = cursor != null
        ? Uri.parse(cursor)
        : Uri.parse('$_approot/delta')
              .replace(queryParameters: {r'$select': _select});
    final r = await sendWithRetry(
      () => _http.get(url, headers: _bearer(access)),
    );
    checkOk(r, 'OneDrive', 'list');
    final b = jsonDecode(r.body) as Map<String, dynamic>;
    return FilePage(
      files: [
        for (final i in (b['value'] as List? ?? []))
          if ((i as Map).containsKey('file') && !i.containsKey('deleted'))
            _toRemote(i.cast<String, dynamic>()),
      ],
      nextCursor: b['@odata.nextLink'] as String?,
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
    final safe = name.replaceAll(_invalidName, '_');
    final item = Uri.encodeComponent(safe);

    if (size == 0) {
      // Upload sessions cannot be empty; a plain PUT can.
      await for (final piece in data) {
        if (piece.isNotEmpty) {
          throw ProviderError('Upload body is larger than the declared size');
        }
      }
      final r = await sendWithRetry(
        () => _http.put(
          Uri.parse('$_approot:/$item:/content').replace(
            queryParameters: {'@microsoft.graph.conflictBehavior': 'rename'},
          ),
          headers: _bearer(access),
          body: const <int>[],
        ),
      );
      checkOk(r, 'OneDrive', 'upload');
      return _toRemote(jsonDecode(r.body) as Map<String, dynamic>);
    }

    final init = await sendWithRetry(
      () => _http.post(
        Uri.parse('$_approot:/$item:/createUploadSession'),
        headers: {..._bearer(access), 'Content-Type': 'application/json'},
        body: jsonEncode({
          'item': {'@microsoft.graph.conflictBehavior': 'rename', 'name': safe},
        }),
      ),
    );
    checkOk(init, 'OneDrive', 'upload start');
    // Pre-authenticated: never send our token to it.
    final uploadUrl = Uri.parse(
      (jsonDecode(init.body) as Map)['uploadUrl'] as String,
    );

    Future<http.Response> put(List<int> chunk, int start) async {
      final r = await sendWithRetry(
        () => _http.put(
          uploadUrl,
          headers: {
            'Content-Range': 'bytes $start-${start + chunk.length - 1}/$size',
          },
          body: chunk,
        ),
      );
      if (r.statusCode != 200 && r.statusCode != 201 && r.statusCode != 202) {
        checkOk(r, 'OneDrive', 'upload chunk');
      }
      return r;
    }

    var sent = 0;
    var buf = <int>[];
    http.Response? last;
    await for (final piece in data) {
      buf.addAll(piece);
      if (sent + buf.length > size) {
        throw ProviderError('Upload body is larger than the declared size');
      }
      while (buf.length >= onedriveChunkSize) {
        final chunk = buf.sublist(0, onedriveChunkSize);
        buf = buf.sublist(onedriveChunkSize);
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

  /// Graph answers 302 to a pre-authenticated URL. Redirects are followed by
  /// hand so our token is never forwarded to the other host.
  @override
  Stream<List<int>> download(AccessToken access, String remoteId) async* {
    final first =
        http.Request(
            'GET',
            Uri.parse('$_graph/me/drive/items/$remoteId/content'),
          )
          ..followRedirects = false
          ..headers.addAll(_bearer(access));
    var resp = await _http.send(first);
    if (resp.isRedirect) {
      final location = resp.headers['location'];
      await resp.stream.drain<void>();
      if (location == null) {
        throw ProviderError('OneDrive download redirect had no location');
      }
      resp = await _http.send(http.Request('GET', Uri.parse(location)));
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      await resp.stream.drain<void>();
      throw ProviderError(
        'OneDrive download failed (${resp.statusCode})',
        status: resp.statusCode,
      );
    }
    yield* resp.stream;
  }

  @override
  Future<void> delete(AccessToken access, String remoteId) async {
    final r = await sendWithRetry(
      () => _http.delete(
        Uri.parse('$_graph/me/drive/items/$remoteId'),
        headers: _bearer(access),
      ),
    );
    if (r.statusCode == 404) return;
    checkOk(r, 'OneDrive', 'delete');
  }

  @override
  Future<RemoteFile> rename(
    AccessToken access,
    String remoteId,
    String newName,
  ) async {
    final r = await sendWithRetry(
      () => _http.patch(
        Uri.parse('$_graph/me/drive/items/$remoteId'),
        headers: {..._bearer(access), 'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': newName.replaceAll(_invalidName, '_'),
          '@microsoft.graph.conflictBehavior': 'fail',
        }),
      ),
    );
    if (r.statusCode == 409) {
      throw ProviderError(
        'A file with that name already exists in this folder',
        status: 409,
      );
    }
    if (r.statusCode == 404) throw ProviderError('File not found', status: 404);
    checkOk(r, 'OneDrive', 'rename');
    return _toRemote(jsonDecode(r.body) as Map<String, dynamic>);
  }
}
