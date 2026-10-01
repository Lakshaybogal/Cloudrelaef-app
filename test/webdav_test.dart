import 'dart:convert';
import 'dart:io';

import 'package:cloudrelaef/data/secure/secret_store.dart';
import 'package:cloudrelaef/services/settings.dart';
import 'package:cloudrelaef/webdav/webdav_manager.dart';
import 'package:cloudrelaef/webdav/webdav_server.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

class DavResponse {
  DavResponse(this.status, this.headers, this.bytes);
  final int status;
  final HttpHeaders headers;
  final List<int> bytes;
  String get body => utf8.decode(bytes);
}

void main() {
  late Harness h;
  late WebDavServer server;
  late Directory tmp;
  late int port;
  final client = HttpClient();

  Future<DavResponse> dav(
    String method,
    String path, {
    Map<String, String> headers = const {},
    List<int>? body,
    bool chunked = false,
    bool auth = true,
    String? host,
  }) async {
    final req = await client.openUrl(
      method,
      Uri.parse('http://127.0.0.1:$port$path'),
    );
    if (auth) {
      req.headers.set(
        'Authorization',
        'Basic ${base64.encode(utf8.encode('cloudrelaef:pw'))}',
      );
    }
    if (host != null) req.headers.host = host;
    headers.forEach(req.headers.set);
    if (body != null) {
      if (chunked) {
        req.headers.chunkedTransferEncoding = true;
      } else {
        req.contentLength = body.length;
      }
      req.add(body);
    }
    final res = await req.close();
    final bytes = [for (final c in await res.toList()) ...c];
    return DavResponse(res.statusCode, res.headers, bytes);
  }

  Future<DavResponse> put(
    String path,
    List<int> body, {
    bool chunked = false,
  }) => dav('PUT', path, body: body, chunked: chunked);

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('cr_dav_test');
    h = Harness(totalA: 1 << 30, totalB: 1 << 30);
    await h.connect(h.a, 'a');
    await h.connect(h.b, 'b');
    server = WebDavServer(
      files: h.files,
      folders: h.folders,
      accounts: h.accounts,
      password: 'pw',
      tempDir: tmp,
    );
    port = await server.start();
  });
  tearDown(() async {
    await server.stop();
    await h.close();
    await tmp.delete(recursive: true);
  });
  tearDownAll(() => client.close(force: true));

  group('security', () {
    test('binds to loopback only', () async {
      expect(server.running, isTrue);
      // Connecting through loopback works; the socket is IPv4 loopback.
      expect((await dav('OPTIONS', '/')).status, 200);
    });

    test('requests without or with wrong credentials get 401', () async {
      final none = await dav('PROPFIND', '/', auth: false);
      expect(none.status, 401);
      expect(none.headers.value('www-authenticate'), startsWith('Basic'));
      final req = await client.openUrl(
        'PROPFIND',
        Uri.parse('http://127.0.0.1:$port/'),
      );
      req.headers.set(
        'Authorization',
        'Basic ${base64.encode(utf8.encode('cloudrelaef:wrong'))}',
      );
      expect((await req.close()).statusCode, 401);
      final req2 = await client.openUrl(
        'PROPFIND',
        Uri.parse('http://127.0.0.1:$port/'),
      );
      req2.headers.set(
        'Authorization',
        'Basic ${base64.encode(utf8.encode('root:pw'))}',
      );
      expect((await req2.close()).statusCode, 401);
      final req3 = await client.openUrl(
        'GET',
        Uri.parse('http://127.0.0.1:$port/'),
      );
      req3.headers.set('Authorization', 'Basic !!!notbase64');
      expect((await req3.close()).statusCode, 401);
    });

    test('nothing is reachable without auth, including writes', () async {
      expect((await dav('PUT', '/x.txt', body: [1], auth: false)).status, 401);
      expect((await dav('DELETE', '/x.txt', auth: false)).status, 401);
      expect((await dav('MKCOL', '/d', auth: false)).status, 401);
      expect(await h.files.list(), isEmpty);
    });

    test('a foreign Host header (DNS rebinding) is refused', () async {
      expect((await dav('PROPFIND', '/', host: 'evil.example')).status, 403);
      expect((await dav('PROPFIND', '/', host: 'localhost')).status, 207);
    });

    test('encoded slashes are rejected; dot segments cannot escape', () async {
      expect((await dav('GET', '/a%2Fb')).status, 400);
      // The URI parser normalises ".." away, so it just resolves to /etc.
      expect((await dav('GET', '/%2e%2e/etc')).status, 404);
    });

    test('error bodies do not leak internals', () async {
      final r = await dav('GET', '/missing');
      expect(r.status, 404);
      expect(r.body, isNot(contains('Exception')));
    });
  });

  group('basics', () {
    test('OPTIONS advertises DAV class 1,2 and methods', () async {
      final r = await dav('OPTIONS', '/');
      expect(r.headers.value('dav'), '1, 2');
      expect(r.headers.value('allow'), contains('PROPFIND'));
      expect(r.headers.value('allow'), contains('MKCOL'));
    });

    test('unknown methods are 405', () async {
      expect((await dav('PATCH', '/')).status, 405);
    });

    test('root PROPFIND depth 0 is a collection with quota', () async {
      final r = await dav('PROPFIND', '/', headers: {'Depth': '0'});
      expect(r.status, 207);
      expect(r.body, contains('<D:collection/>'));
      expect(r.body, contains('quota-available-bytes'));
      expect(r.body, isNot(contains('getcontentlength')));
    });

    test('LOCK and UNLOCK are accepted (needed by Finder)', () async {
      final l = await dav('LOCK', '/x.txt');
      expect(l.status, 200);
      expect(l.headers.value('lock-token'), startsWith('<opaquelocktoken:'));
      expect((await dav('UNLOCK', '/x.txt')).status, 204);
    });
  });

  group('files', () {
    test(
      'PUT creates a file (201), GET returns it, HEAD has headers',
      () async {
        expect(
          (await put('/hello.txt', utf8.encode('hello world'))).status,
          201,
        );
        final get = await dav('GET', '/hello.txt');
        expect(get.status, 200);
        expect(get.body, 'hello world');
        expect(get.headers.contentLength, 11);
        expect(get.headers.contentType?.mimeType, 'text/plain');
        final head = await dav('HEAD', '/hello.txt');
        expect(head.status, 200);
        expect(head.headers.contentLength, 11);
        expect(head.bytes, isEmpty);
      },
    );

    test('chunked PUT (no Content-Length) is buffered and stored', () async {
      final data = List.generate(5000, (i) => i % 251);
      expect((await put('/big.bin', data, chunked: true)).status, 201);
      expect((await dav('GET', '/big.bin')).bytes, data);
      expect(
        await tmp.list().toList(),
        isEmpty,
        reason: 'temp file cleaned up',
      );
    });

    test('empty file', () async {
      expect((await put('/empty', [])).status, 201);
      expect((await dav('GET', '/empty')).bytes, isEmpty);
    });

    test('names with spaces, unicode and XML characters round-trip', () async {
      const name = 'my file é & <b>.txt';
      expect((await put('/${Uri.encodeComponent(name)}', [1, 2])).status, 201);
      final list = await dav('PROPFIND', '/', headers: {'Depth': '1'});
      expect(list.body, contains('my file é &amp; &lt;b&gt;.txt'));
      expect(
        list.body,
        contains('<D:href>/my%20file%20%C3%A9%20&amp;%20%3Cb%3E.txt</D:href>'),
      );
      expect((await dav('GET', '/${Uri.encodeComponent(name)}')).bytes, [1, 2]);
    });

    test(
      'PROPFIND depth 1 lists files with size, type, etag and date',
      () async {
        await put('/a.txt', [1, 2, 3]);
        final r = await dav('PROPFIND', '/', headers: {'Depth': '1'});
        expect(r.body, contains('<D:href>/a.txt</D:href>'));
        expect(r.body, contains('<D:getcontentlength>3</D:getcontentlength>'));
        expect(r.body, contains('getetag'));
        expect(r.body, contains('GMT'));
      },
    );

    test('PROPFIND on a file and on a missing path', () async {
      await put('/a.txt', [1]);
      final f = await dav('PROPFIND', '/a.txt', headers: {'Depth': '0'});
      expect(f.status, 207);
      expect(f.body, contains('<D:resourcetype/>'));
      expect((await dav('PROPFIND', '/nope')).status, 404);
    });

    test('overwriting replaces the file (204) and keeps the name', () async {
      await put('/a.txt', [1, 1]);
      expect((await put('/a.txt', [2, 2, 2])).status, 204);
      expect((await dav('GET', '/a.txt')).bytes, [2, 2, 2]);
      final r = await dav('PROPFIND', '/', headers: {'Depth': '1'});
      expect(RegExp('<D:href>/a.txt</D:href>').allMatches(r.body).length, 1);
      expect(await h.files.list(), hasLength(1));
    });

    test('a file that does not exist is 404; a folder cannot be GET', () async {
      expect((await dav('GET', '/nope')).status, 404);
      await dav('MKCOL', '/d');
      expect((await dav('GET', '/d')).status, 405);
    });

    test('PUT into a missing folder is 409; onto a folder is 405', () async {
      expect((await put('/missing/x.txt', [1])).status, 409);
      await dav('MKCOL', '/d');
      expect((await put('/d', [1])).status, 405);
    });

    test('uploads are placed across clouds like the app does', () async {
      for (var i = 0; i < 4; i++) {
        await put('/f$i', List.filled(100, 1));
      }
      final owners = (await h.files.list()).map((f) => f.accountId).toSet();
      expect(owners.length, 2);
    });

    test('no capacity is 507', () async {
      final tiny = Harness(totalA: 10, totalB: 10);
      await tiny.connect(tiny.a, 'a');
      final s = WebDavServer(
        files: tiny.files,
        folders: tiny.folders,
        accounts: tiny.accounts,
        password: 'pw',
        tempDir: tmp,
      );
      final p = await s.start();
      final req = await client.openUrl(
        'PUT',
        Uri.parse('http://127.0.0.1:$p/big'),
      );
      req.headers.set(
        'Authorization',
        'Basic ${base64.encode(utf8.encode('cloudrelaef:pw'))}',
      );
      req.contentLength = 100;
      req.add(List.filled(100, 1));
      expect((await req.close()).statusCode, 507);
      await s.stop();
      await tiny.close();
    });
  });

  group('folders', () {
    test('MKCOL creates; again is 405; missing parent is 409', () async {
      expect((await dav('MKCOL', '/docs')).status, 201);
      expect((await dav('MKCOL', '/docs')).status, 405);
      expect((await dav('MKCOL', '/a/b')).status, 409);
      expect((await dav('MKCOL', '/docs/sub')).status, 201);
      expect((await h.folders.list()).length, 2);
    });

    test('files in folders; PROPFIND lists children only one level', () async {
      await dav('MKCOL', '/docs');
      await dav('MKCOL', '/docs/sub');
      await put('/docs/a.txt', [1]);
      await put('/docs/sub/b.txt', [2]);
      final r = await dav('PROPFIND', '/docs', headers: {'Depth': '1'});
      expect(r.body, contains('<D:href>/docs/</D:href>'));
      expect(r.body, contains('/docs/a.txt'));
      expect(r.body, contains('/docs/sub/'));
      expect(r.body, isNot(contains('b.txt')));
      expect((await dav('GET', '/docs/sub/b.txt')).bytes, [2]);
    });

    test('folder lookup is case-insensitive as a fallback', () async {
      await dav('MKCOL', '/Docs');
      await put('/docs/x.txt', [1]);
      expect((await dav('GET', '/Docs/x.txt')).status, 200);
    });

    test('DELETE a file moves it to the trash (recoverable)', () async {
      await put('/a.txt', [1]);
      expect((await dav('DELETE', '/a.txt')).status, 204);
      expect((await dav('GET', '/a.txt')).status, 404);
      expect(await h.files.list(), isEmpty);
      expect(await h.files.list(trashed: true), hasLength(1));
    });

    test('DELETE a folder removes it and trashes its contents', () async {
      await dav('MKCOL', '/docs');
      await dav('MKCOL', '/docs/sub');
      await put('/docs/a.txt', [1]);
      await put('/docs/sub/b.txt', [2]);
      expect((await dav('DELETE', '/docs')).status, 204);
      expect(await h.folders.list(), isEmpty);
      expect(await h.files.list(), isEmpty);
      expect(await h.files.list(trashed: true), hasLength(2));
      expect((await dav('PROPFIND', '/docs')).status, 404);
    });

    test('DELETE missing is 404; the root cannot be deleted', () async {
      expect((await dav('DELETE', '/nope')).status, 404);
      expect((await dav('DELETE', '/')).status, 403);
    });
  });

  group('move and copy', () {
    String dest(String path) => 'http://127.0.0.1:$port$path';

    test('MOVE renames a file', () async {
      await put('/old.txt', [1, 2]);
      expect(
        (await dav(
          'MOVE',
          '/old.txt',
          headers: {'Destination': dest('/new.txt')},
        )).status,
        201,
      );
      expect((await dav('GET', '/old.txt')).status, 404);
      expect((await dav('GET', '/new.txt')).bytes, [1, 2]);
    });

    test('MOVE into a folder', () async {
      await dav('MKCOL', '/d');
      await put('/a.txt', [7]);
      expect(
        (await dav(
          'MOVE',
          '/a.txt',
          headers: {'Destination': dest('/d/a.txt')},
        )).status,
        201,
      );
      expect((await dav('GET', '/d/a.txt')).bytes, [7]);
      expect((await dav('GET', '/a.txt')).status, 404);
    });

    test('MOVE renames and moves a folder', () async {
      await dav('MKCOL', '/a');
      await dav('MKCOL', '/b');
      await put('/a/f.txt', [1]);
      expect(
        (await dav(
          'MOVE',
          '/a',
          headers: {'Destination': dest('/b/renamed')},
        )).status,
        201,
      );
      expect((await dav('GET', '/b/renamed/f.txt')).bytes, [1]);
      expect((await dav('PROPFIND', '/a')).status, 404);
    });

    test('a folder cannot move into itself', () async {
      await dav('MKCOL', '/a');
      await dav('MKCOL', '/a/b');
      final r = await dav(
        'MOVE',
        '/a',
        headers: {'Destination': dest('/a/b/a')},
      );
      expect(r.status, 409);
    });

    test('Overwrite: F refuses (412); default replaces (204)', () async {
      await put('/a.txt', [1]);
      await put('/b.txt', [2]);
      final no = await dav(
        'MOVE',
        '/a.txt',
        headers: {'Destination': dest('/b.txt'), 'Overwrite': 'F'},
      );
      expect(no.status, 412);
      final yes = await dav(
        'MOVE',
        '/a.txt',
        headers: {'Destination': dest('/b.txt')},
      );
      expect(yes.status, 204);
      expect((await dav('GET', '/b.txt')).bytes, [1]);
      expect((await dav('GET', '/a.txt')).status, 404);
    });

    test(
      'MOVE of a missing source is 404; missing destination folder is 409',
      () async {
        expect(
          (await dav(
            'MOVE',
            '/nope',
            headers: {'Destination': dest('/x')},
          )).status,
          404,
        );
        await put('/a.txt', [1]);
        expect(
          (await dav(
            'MOVE',
            '/a.txt',
            headers: {'Destination': dest('/no/dir/a.txt')},
          )).status,
          409,
        );
        expect((await dav('MOVE', '/a.txt')).status, 400);
      },
    );

    test('COPY duplicates a file; the original stays', () async {
      await put('/a.txt', [4, 5, 6]);
      expect(
        (await dav(
          'COPY',
          '/a.txt',
          headers: {'Destination': dest('/copy.txt')},
        )).status,
        201,
      );
      expect((await dav('GET', '/copy.txt')).bytes, [4, 5, 6]);
      expect((await dav('GET', '/a.txt')).bytes, [4, 5, 6]);
      expect(await h.files.list(), hasLength(2));
    });

    test(
      'COPY onto an existing file replaces it; Overwrite F refuses',
      () async {
        await put('/a.txt', [1]);
        await put('/b.txt', [2]);
        expect(
          (await dav(
            'COPY',
            '/a.txt',
            headers: {'Destination': dest('/b.txt'), 'Overwrite': 'F'},
          )).status,
          412,
        );
        expect(
          (await dav(
            'COPY',
            '/a.txt',
            headers: {'Destination': dest('/b.txt')},
          )).status,
          204,
        );
        expect((await dav('GET', '/b.txt')).bytes, [1]);
      },
    );

    test('COPY of a folder is not implemented', () async {
      await dav('MKCOL', '/a');
      expect(
        (await dav('COPY', '/a', headers: {'Destination': dest('/b')})).status,
        501,
      );
    });

    test('moving onto itself is refused', () async {
      await put('/a.txt', [1]);
      expect(
        (await dav(
          'MOVE',
          '/a.txt',
          headers: {'Destination': dest('/a.txt')},
        )).status,
        403,
      );
    });
  });

  group('file manager noise', () {
    test(
      '.DS_Store and AppleDouble files are accepted but never stored',
      () async {
        expect((await put('/.DS_Store', [1])).status, 201);
        expect((await put('/._photo.jpg', [1])).status, 201);
        expect((await put('/Thumbs.db', [1])).status, 201);
        expect((await dav('GET', '/.DS_Store')).status, 404);
        expect(await h.files.list(), isEmpty);
        expect(isJunkName('notes.txt'), isFalse);
      },
    );
  });

  group('duplicate names', () {
    test('two files with one name are both reachable', () async {
      // Same name in two clouds is possible in the index (e.g. after a sync).
      await put('/a.txt', [1]);
      final first = (await h.files.list()).single;
      await h.db.customStatement(
        "INSERT INTO files (account_id, remote_id, name, path, size, mime, indexed_at) "
        "SELECT account_id, 'dup', name, path, 1, mime, indexed_at FROM files WHERE id = ${first.id}",
      );
      final r = await dav('PROPFIND', '/', headers: {'Depth': '1'});
      expect(r.body, contains('/a.txt'));
      expect(r.body, contains('/a%20(2).txt'));
    });
  });

  group('manager', () {
    late WebDavManager m;
    late InMemorySecretStore secrets;

    setUp(() {
      secrets = InMemorySecretStore();
      m = WebDavManager(
        settings: SettingsStore(h.db),
        secrets: secrets,
        files: h.files,
        folders: h.folders,
        accounts: h.accounts,
        tempDir: tmp,
      );
    });
    tearDown(() => m.dispose());

    test('off by default; start and stop persist the switch', () async {
      expect(await m.isEnabled(), isFalse);
      expect(m.running, isFalse);
      await m.setPort(0 + 18765);
      await m.start();
      expect(m.running, isTrue);
      expect(m.url, 'http://127.0.0.1:18765/');
      expect(await m.isEnabled(), isTrue);
      await m.stop();
      expect(m.running, isFalse);
      expect(await m.isEnabled(), isFalse);
    });

    test(
      'the password is generated once, strong and kept in the keystore',
      () async {
        final pw = await m.password();
        expect(pw.length, 24);
        expect(await m.password(), pw);
        expect(await secrets.read('webdav_password'), pw);
        final regenerated = await m.regeneratePassword();
        expect(regenerated, isNot(pw));
      },
    );

    test(
      'regenerating restarts the server so the old password stops working',
      () async {
        await m.setPort(18766);
        await m.start();
        final old = await m.password();
        await m.regeneratePassword();
        final req = await client.openUrl('PROPFIND', Uri.parse('${m.url}'));
        req.headers.set(
          'Authorization',
          'Basic ${base64.encode(utf8.encode('cloudrelaef:$old'))}',
        );
        expect((await req.close()).statusCode, 401);
        final fresh = await m.password();
        final req2 = await client.openUrl('PROPFIND', Uri.parse('${m.url}'));
        req2.headers.set(
          'Authorization',
          'Basic ${base64.encode(utf8.encode('cloudrelaef:$fresh'))}',
        );
        expect((await req2.close()).statusCode, 207);
      },
    );

    test('port is validated; a busy port is a clear error', () async {
      expect(() => m.setPort(80), throwsArgumentError);
      expect(() => m.setPort(70000), throwsArgumentError);
      await m.setPort(port); // taken by the test server
      await expectLater(m.start(), throwsA(isA<StateError>()));
      expect(m.running, isFalse);
    });

    test(
      'restoreState brings back an enabled server, and survives a busy port',
      () async {
        await m.setPort(18767);
        await m.start();
        await m.dispose(); // app closes; switch stays on
        expect(await m.isEnabled(), isTrue);
        await m.restoreState();
        expect(m.running, isTrue);
        await m.dispose();
        await m.setPort(port);
        await m.restoreState(); // port busy: must not throw
        expect(m.running, isFalse);
      },
    );
  });
}
