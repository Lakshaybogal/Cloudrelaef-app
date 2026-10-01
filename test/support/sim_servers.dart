import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Tiny in-memory imitations of the three cloud APIs, good enough to run the
/// shared adapter contract against the real adapter code.
class Item {
  Item(this.id, this.name, this.bytes);
  final String id;
  String name;
  final List<int> bytes;
}

class SimStore {
  final Map<String, Item> items = {};
  int _n = 0;
  String nextId(String prefix) => '$prefix${++_n}';
  int get used => items.values.fold(0, (a, b) => a + b.bytes.length);
  bool nameTaken(String name, [String? except]) =>
      items.values.any((i) => i.id != except && i.name == name);
}

http.Response jsonResp(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

const _page = 2;

/// Parses "bytes 0-4/5" -> (start, end, total).
(int, int, int) parseRange(String h) {
  final m = RegExp(r'bytes (\d+)-(\d+)/(\d+)').firstMatch(h)!;
  return (int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
}

// ---------------------------------------------------------------- Dropbox
class DropboxSim {
  final store = SimStore();
  final Map<String, List<int>> sessions = {};

  Map<String, dynamic> meta(Item i) => {
    '.tag': 'file',
    'id': i.id,
    'name': i.name,
    'size': i.bytes.length,
    'server_modified': '2026-01-01T00:00:00Z',
    'path_display': '/${i.name}',
    'content_hash': 'h${i.id}',
  };

  Item _commit(Map<String, dynamic> commit, List<int> bytes) {
    var name = (commit['path'] as String).substring(1);
    if (store.nameTaken(name) && commit['autorename'] == true) {
      name = '$name (1)';
    }
    final item = Item(store.nextId('id:'), name, bytes);
    store.items[item.id] = item;
    return item;
  }

  MockClient client() => MockClient((req) async {
    final path = req.url.path;
    if (req.url.host == 'api.dropboxapi.com' && path == '/oauth2/token') {
      return jsonResp({
        'access_token': 'at',
        'refresh_token': 'rt',
        'expires_in': 14400,
      });
    }
    final arg = req.headers['Dropbox-API-Arg'] == null
        ? null
        : jsonDecode(req.headers['Dropbox-API-Arg']!) as Map<String, dynamic>;
    final isJson =
        req.headers['Content-Type']?.startsWith('application/json') ?? false;
    final body = isJson && req.bodyBytes.isNotEmpty
        ? jsonDecode(req.body) as Map<String, dynamic>
        : <String, dynamic>{};
    switch (path) {
      case '/2/users/get_current_account':
        return jsonResp({'account_id': 'dbid:1', 'email': 'me@dbx.com'});
      case '/2/users/get_space_usage':
        return jsonResp({
          'used': store.used,
          'allocation': {'.tag': 'individual', 'allocated': 1000000},
        });
      case '/2/files/upload':
        return jsonResp(meta(_commit(arg!, req.bodyBytes)));
      case '/2/files/upload_session/start':
        final id = 'sess${sessions.length + 1}';
        sessions[id] = [...req.bodyBytes];
        return jsonResp({'session_id': id});
      case '/2/files/upload_session/append_v2':
        final c = arg!['cursor'] as Map;
        final buf = sessions[c['session_id']]!;
        if (buf.length != c['offset']) return http.Response('bad offset', 409);
        buf.addAll(req.bodyBytes);
        return jsonResp({});
      case '/2/files/upload_session/finish':
        final c = arg!['cursor'] as Map;
        final buf = sessions[c['session_id']]!;
        if (buf.length != c['offset']) return http.Response('bad offset', 409);
        buf.addAll(req.bodyBytes);
        return jsonResp(
          meta(_commit(arg['commit'] as Map<String, dynamic>, buf)),
        );
      case '/2/files/download':
        final i = store.items[arg!['path']];
        return i == null
            ? http.Response('{"error_summary":"path/not_found"}', 409)
            : http.Response.bytes(i.bytes, 200);
      case '/2/files/list_folder':
      case '/2/files/list_folder/continue':
        final start = path.endsWith('continue')
            ? int.parse((body['cursor'] as String).split(':')[1])
            : 0;
        final all = store.items.values.toList();
        final page = all.skip(start).take(_page).toList();
        final end = start + page.length;
        return jsonResp({
          'entries': [
            for (final i in page) meta(i),
            {'.tag': 'folder', 'name': 'ignored', 'id': 'id:folder'},
          ],
          'cursor': 'c:$end',
          'has_more': end < all.length,
        });
      case '/2/files/get_metadata':
        final i = store.items[body['path']];
        return i == null ? http.Response('not_found', 409) : jsonResp(meta(i));
      case '/2/files/move_v2':
        final i = store.items[body['from_path']];
        if (i == null) return http.Response('not_found', 409);
        final newName = (body['to_path'] as String).substring(1);
        if (store.nameTaken(newName, i.id)) {
          return http.Response('{"error_summary":"to/conflict/file/.."}', 409);
        }
        i.name = newName;
        return jsonResp({'metadata': meta(i)});
      case '/2/files/delete_v2':
        final removed = store.items.remove(body['path']);
        return removed == null
            ? http.Response('{"error_summary":"path_lookup/not_found/.."}', 409)
            : jsonResp({'metadata': meta(removed)});
    }
    return http.Response('unexpected $path', 500);
  });
}

// --------------------------------------------------------------- OneDrive
class OneDriveSim {
  final store = SimStore();
  final Map<String, ({String name, List<int> buf})> sessions = {};
  final List<String> authSeenByRedirectTargets = [];

  Map<String, dynamic> meta(Item i) => {
    'id': i.id,
    'name': i.name,
    'size': i.bytes.length,
    'file': {
      'mimeType': 'application/octet-stream',
      'hashes': {'sha1Hash': 'sha${i.id}'},
    },
    'lastModifiedDateTime': '2026-01-01T00:00:00Z',
    'parentReference': {'path': '/drive/root:/Apps/Cloudrelaef'},
  };

  Item _add(String name, List<int> bytes) {
    final item = Item(store.nextId('o'), name, bytes);
    store.items[item.id] = item;
    return item;
  }

  MockClient client() => MockClient((req) async {
    final host = req.url.host;
    final path = Uri.decodeFull(req.url.path);
    if (host == 'login.microsoftonline.com') {
      return jsonResp({
        'access_token': 'at',
        'refresh_token': 'rt-new',
        'expires_in': 3600,
      });
    }
    if (host == 'upload.example') {
      if (req.headers.containsKey('Authorization')) {
        return http.Response('token leaked to upload url', 400);
      }
      final s = sessions[path]!;
      final (start, end, total) = parseRange(req.headers['Content-Range']!);
      if (s.buf.length != start) return http.Response('bad range', 416);
      s.buf.addAll(req.bodyBytes);
      if (end + 1 == total) {
        return jsonResp(meta(_add(s.name, s.buf)), 201);
      }
      return jsonResp({
        'nextExpectedRanges': ['${end + 1}-'],
      }, 202);
    }
    if (host == 'dl.example') {
      if (req.headers.containsKey('Authorization')) {
        return http.Response('token forwarded on redirect', 400);
      }
      final i = store.items[path.substring(1)]!;
      return http.Response.bytes(i.bytes, 200);
    }
    if (path == '/v1.0/me') {
      return jsonResp({'id': 'ms1', 'mail': 'me@outlook.com'});
    }
    if (path == '/v1.0/me/drive') {
      return jsonResp({
        'quota': {'total': 5000000, 'used': store.used},
      });
    }
    final createMatch = RegExp(r'/approot:/(.+):/createUploadSession$')
        .firstMatch(path);
    if (createMatch != null) {
      final id = '/s/${sessions.length + 1}';
      sessions['/s/${sessions.length + 1}'] = (
        name: jsonDecode(req.body)['item']['name'] as String,
        buf: <int>[],
      );
      return jsonResp({'uploadUrl': 'https://upload.example$id'});
    }
    final putContent = RegExp(r'/approot:/(.+):/content$').firstMatch(path);
    if (putContent != null && req.method == 'PUT') {
      return jsonResp(meta(_add(putContent[1]!, req.bodyBytes)), 201);
    }
    if (path.endsWith('/approot/delta') || path == '/v1.0/delta-page') {
      final start = int.tryParse(req.url.queryParameters['n'] ?? '0') ?? 0;
      final all = store.items.values.toList();
      final page = all.skip(start).take(_page).toList();
      final end = start + page.length;
      return jsonResp({
        'value': [
          for (final i in page) meta(i),
          {'id': 'folder', 'name': 'ignored', 'folder': {}},
          {'id': 'gone', 'name': 'gone', 'file': {}, 'deleted': {}},
        ],
        if (end < all.length)
          '@odata.nextLink':
              'https://graph.microsoft.com/v1.0/delta-page?n=$end',
      });
    }
    final itemMatch = RegExp(r'/me/drive/items/([^/]+)(/content)?$')
        .firstMatch(path);
    if (itemMatch != null) {
      final id = itemMatch[1]!;
      final item = store.items[id];
      if (itemMatch[2] != null) {
        return item == null
            ? http.Response('', 404)
            : http.Response(
                '',
                302,
                headers: {'location': 'https://dl.example/$id'},
                isRedirect: true,
              );
      }
      if (req.method == 'DELETE') {
        return store.items.remove(id) == null
            ? http.Response('', 404)
            : http.Response('', 204);
      }
      if (req.method == 'PATCH') {
        if (item == null) return http.Response('', 404);
        final newName = jsonDecode(req.body)['name'] as String;
        if (store.nameTaken(newName, id)) {
          return http.Response('{"error":{"code":"nameAlreadyExists"}}', 409);
        }
        item.name = newName;
        return jsonResp(meta(item));
      }
    }
    return http.Response('unexpected $path', 500);
  });
}

// ----------------------------------------------------------------- Google
class GoogleSim {
  final store = SimStore();
  final Map<String, ({String name, List<int> buf})> sessions = {};

  Map<String, dynamic> meta(Item i) => {
    'id': i.id,
    'name': i.name,
    'size': '${i.bytes.length}',
    'mimeType': 'application/octet-stream',
    'md5Checksum': 'md5${i.id}',
    'modifiedTime': '2026-01-01T00:00:00.000Z',
  };

  Item _add(String name, List<int> bytes) {
    final item = Item(store.nextId('g'), name, bytes);
    store.items[item.id] = item;
    return item;
  }

  MockClient client() => MockClient((req) async {
    final host = req.url.host;
    final path = req.url.path;
    if (host == 'oauth2.googleapis.com') {
      return jsonResp({
        'access_token': 'at',
        'refresh_token': 'rt',
        'expires_in': 3600,
      });
    }
    if (host == 'up.example') {
      final s = sessions[path]!;
      final range = req.headers['Content-Range']!;
      if (range.startsWith('bytes */')) {
        return jsonResp(meta(_add(s.name, const [])), 200);
      }
      final (start, end, total) = parseRange(range);
      if (s.buf.length != start) return http.Response('bad range', 416);
      s.buf.addAll(req.bodyBytes);
      return end + 1 == total
          ? jsonResp(meta(_add(s.name, s.buf)), 200)
          : http.Response('', 308);
    }
    if (path == '/upload/drive/v3/files') {
      final id = '/g/${sessions.length + 1}';
      sessions[id] = (
        name: jsonDecode(req.body)['name'] as String,
        buf: <int>[],
      );
      return http.Response(
        '',
        200,
        headers: {'location': 'https://up.example$id'},
      );
    }
    if (path == '/drive/v3/about') {
      return req.url.queryParameters['fields']!.startsWith('storageQuota')
          ? jsonResp({
              'storageQuota': {'limit': '1000000', 'usage': '${store.used}'},
            })
          : jsonResp({
              'user': {'emailAddress': 'me@gmail.com', 'permissionId': 'pid1'},
            });
    }
    if (path == '/drive/v3/files') {
      final start =
          int.tryParse(req.url.queryParameters['pageToken'] ?? '0') ?? 0;
      final all = store.items.values.toList();
      final page = all.skip(start).take(_page).toList();
      final end = start + page.length;
      return jsonResp({
        'files': [for (final i in page) meta(i)],
        if (end < all.length) 'nextPageToken': '$end',
      });
    }
    final m = RegExp(r'/drive/v3/files/([^/]+)$').firstMatch(path);
    if (m != null) {
      final item = store.items[m[1]!];
      if (item == null) return http.Response('', 404);
      switch (req.method) {
        case 'GET':
          return http.Response.bytes(Uint8List.fromList(item.bytes), 200);
        case 'PATCH':
          item.name = jsonDecode(req.body)['name'] as String;
          return jsonResp(meta(item));
        case 'DELETE':
          store.items.remove(item.id);
          return http.Response('', 204);
      }
    }
    return http.Response('unexpected $path', 500);
  });
}
