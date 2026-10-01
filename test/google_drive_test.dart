import 'dart:convert';

import 'package:cloudrelaef/providers/google_drive.dart';
import 'package:cloudrelaef/providers/http_util.dart' as h;
import 'package:cloudrelaef/providers/storage_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _now = DateTime.utc(2026);
final _tok = AccessToken(token: 'tok', expiresAt: DateTime.utc(2100));

http.Response _json(
  Object body, [
  int status = 200,
  Map<String, String>? headers,
]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json', ...?headers},
);

GoogleDriveProvider _provider(
  MockClientHandler handler, {
  String? secret = 's3cret',
}) => GoogleDriveProvider(
  OAuthClientConfig(clientId: 'cid', clientSecret: secret),
  client: MockClient(handler),
  now: () => _now,
);

Map<String, dynamic> _file(
  String id, {
  String name = 'a.txt',
  Object size = '5',
}) => {
  'id': id,
  'name': name,
  'size': size,
  'mimeType': 'text/plain',
  'md5Checksum': 'abc',
  'modifiedTime': '2026-01-01T00:00:00.000Z',
};

void main() {
  setUp(() => h.sleeper = (_) async {});

  test('auth url asks for offline access, PKCE and consent', () {
    final u = _provider((_) async => _json({})).authUrl(
      state: 'st',
      redirectUri: 'http://127.0.0.1:1/',
      codeChallenge: 'ch',
    );
    expect(u.host, 'accounts.google.com');
    final q = u.queryParameters;
    expect(q['client_id'], 'cid');
    expect(q['access_type'], 'offline');
    expect(q['prompt'], 'consent');
    expect(q['code_challenge_method'], 'S256');
    expect(q['code_challenge'], 'ch');
    expect(q['scope'], googleDefaultScope);
  });

  test(
    'exchangeCode sends verifier + secret and looks up the account',
    () async {
      final seen = <String>[];
      final p = _provider((req) async {
        seen.add('${req.method} ${req.url.path}');
        if (req.url.host == 'oauth2.googleapis.com') {
          expect(req.bodyFields['code_verifier'], 'ver');
          expect(req.bodyFields['client_secret'], 's3cret');
          expect(req.bodyFields['grant_type'], 'authorization_code');
          return _json({
            'access_token': 'at',
            'refresh_token': 'rt',
            'expires_in': 100,
          });
        }
        expect(req.headers['Authorization'], 'Bearer at');
        return _json({
          'user': {'emailAddress': 'me@x.com', 'permissionId': 'pid'},
        });
      });
      final t = await p.exchangeCode(
        code: 'c',
        redirectUri: 'r',
        verifier: 'ver',
      );
      expect(t.refreshToken, 'rt');
      expect(t.accountId, 'pid');
      expect(t.displayName, 'me@x.com');
      expect(t.access.expiresAt, _now.add(const Duration(seconds: 100)));
      expect(seen.length, 2);
    },
  );

  test('missing refresh token is a clear error', () async {
    final p = _provider((_) async => _json({'access_token': 'at'}));
    expect(
      () => p.exchangeCode(code: 'c', redirectUri: 'r', verifier: 'v'),
      throwsA(isA<ProviderError>()),
    );
  });

  test('no client secret is sent when none is configured', () async {
    final p = _provider((req) async {
      expect(req.bodyFields.containsKey('client_secret'), isFalse);
      return _json({'access_token': 'at'});
    }, secret: null);
    expect((await p.refreshToken('rt')).token, 'at');
  });

  test('invalid_grant means reauth', () async {
    final p = _provider((_) async => _json({'error': 'invalid_grant'}, 400));
    expect(() => p.refreshToken('rt'), throwsA(isA<ReauthRequired>()));
  });

  test('quota: unlimited accounts have no limit', () async {
    final p = _provider(
      (_) async => _json({
        'storageQuota': {'usage': '10'},
      }),
    );
    final q = await p.getQuota(_tok);
    expect(q.total, isNull);
    expect(q.used, 10);
    final p2 = _provider(
      (_) async => _json({
        'storageQuota': {'limit': '100', 'usage': '10'},
      }),
    );
    expect((await p2.getQuota(_tok)).total, 100);
  });

  test('list pages with a cursor and skips nothing it is given', () async {
    final p = _provider((req) async {
      expect(req.url.queryParameters['q'], contains('trashed = false'));
      if (req.url.queryParameters['pageToken'] == null) {
        return _json({
          'files': [_file('1')],
          'nextPageToken': 'n',
        });
      }
      expect(req.url.queryParameters['pageToken'], 'n');
      return _json({
        'files': [_file('2', size: '0')],
      });
    });
    final first = await p.listFiles(_tok);
    expect(first.nextCursor, 'n');
    expect(first.files.single.remoteId, '1');
    final second = await p.listFiles(_tok, cursor: first.nextCursor);
    expect(second.nextCursor, isNull);
  });

  test('retries on 429 then succeeds', () async {
    var n = 0;
    final p = _provider((_) async {
      n++;
      if (n < 3) {
        return http.Response('slow down', 429, headers: {'retry-after': '1'});
      }
      return _json({
        'storageQuota': {'usage': '1'},
      });
    });
    expect((await p.getQuota(_tok)).used, 1);
    expect(n, 3);
  });

  test('retries 403 rateLimitExceeded but not plain 403', () async {
    var n = 0;
    final p = _provider((_) async {
      n++;
      return n == 1
          ? http.Response(
              '{"error":{"errors":[{"reason":"rateLimitExceeded"}]}}',
              403,
            )
          : _json({
              'storageQuota': {'usage': '1'},
            });
    });
    await p.getQuota(_tok);
    expect(n, 2);
    final denied = _provider((_) async => http.Response('forbidden', 403));
    expect(() => denied.getQuota(_tok), throwsA(isA<ProviderError>()));
  });

  test('error messages never contain the token', () async {
    final p = _provider((_) async => http.Response('nope tok', 500));
    try {
      await p.getQuota(_tok);
      fail('should throw');
    } on ProviderError catch (e) {
      expect(e.toString(), isNot(contains('tok')));
    }
  });

  group('upload', () {
    test('small file: one chunk with the right Content-Range', () async {
      final ranges = <String>[];
      final p = _provider((req) async {
        if (req.url.host == 'www.googleapis.com' && req.method == 'POST') {
          expect(req.headers['X-Upload-Content-Length'], '5');
          expect(jsonDecode(req.body), {'name': 'a.txt'});
          return http.Response(
            '',
            200,
            headers: {'location': 'https://up.example/session'},
          );
        }
        ranges.add(req.headers['Content-Range']!);
        expect(req.bodyBytes, [1, 2, 3, 4, 5]);
        return _json(_file('new'), 200);
      });
      final f = await p.upload(
        _tok,
        name: 'a.txt',
        size: 5,
        mime: 'text/plain',
        data: Stream.fromIterable([
          [1, 2],
          [3, 4, 5],
        ]),
      );
      expect(f.remoteId, 'new');
      expect(ranges, ['bytes 0-4/5']);
    });

    test(
      'large file is chunked on 256 KiB multiples with 308 in between',
      () async {
        final size = googleChunkSize + 10;
        final ranges = <String>[];
        final p = _provider((req) async {
          if (req.method == 'POST') {
            return http.Response(
              '',
              200,
              headers: {'location': 'https://up.example/s'},
            );
          }
          ranges.add(req.headers['Content-Range']!);
          return ranges.length == 1
              ? http.Response('', 308)
              : _json(_file('big'), 201);
        });
        await p.upload(
          _tok,
          name: 'big',
          size: size,
          mime: 'x/y',
          data: Stream.value(List.filled(size, 7)),
        );
        expect(googleChunkSize % (256 * 1024), 0);
        expect(ranges, [
          'bytes 0-${googleChunkSize - 1}/$size',
          'bytes $googleChunkSize-${size - 1}/$size',
        ]);
      },
    );

    test('empty file uses bytes */0', () async {
      final ranges = <String>[];
      final p = _provider((req) async {
        if (req.method == 'POST') {
          return http.Response(
            '',
            200,
            headers: {'location': 'https://up.example/s'},
          );
        }
        ranges.add(req.headers['Content-Range']!);
        return _json(_file('e', size: '0'));
      });
      await p.upload(
        _tok,
        name: 'e',
        size: 0,
        mime: 'x/y',
        data: const Stream.empty(),
      );
      expect(ranges, ['bytes */0']);
    });

    test('body shorter or longer than declared is rejected', () async {
      final p = _provider((req) async {
        if (req.method == 'POST') {
          return http.Response(
            '',
            200,
            headers: {'location': 'https://up.example/s'},
          );
        }
        return _json(_file('x'));
      });
      expect(
        () => p.upload(
          _tok,
          name: 'a',
          size: 5,
          mime: 'x/y',
          data: Stream.value([1, 2]),
        ),
        throwsA(isA<ProviderError>()),
      );
      expect(
        () => p.upload(
          _tok,
          name: 'a',
          size: 1,
          mime: 'x/y',
          data: Stream.value([1, 2]),
        ),
        throwsA(isA<ProviderError>()),
      );
    });
  });

  test('download streams the bytes and surfaces errors', () async {
    final ok = _provider((req) async {
      expect(req.url.queryParameters['alt'], 'media');
      return http.Response.bytes([1, 2, 3], 200);
    });
    final bytes = [
      for (final c in await ok.download(_tok, 'id').toList()) ...c,
    ];
    expect(bytes, [1, 2, 3]);
    final bad = _provider((_) async => http.Response('', 404));
    await expectLater(
      bad.download(_tok, 'id').toList(),
      throwsA(isA<ProviderError>().having((e) => e.status, 'status', 404)),
    );
  });

  test('rename patches the name; 404 is an error', () async {
    final p = _provider((req) async {
      expect(req.method, 'PATCH');
      expect(jsonDecode(req.body), {'name': 'new.txt'});
      return _json(_file('1', name: 'new.txt'));
    });
    expect((await p.rename(_tok, '1', 'new.txt')).name, 'new.txt');
    final gone = _provider((_) async => http.Response('', 404));
    expect(() => gone.rename(_tok, '1', 'x'), throwsA(isA<ProviderError>()));
  });

  test('delete treats 404 as already deleted', () async {
    await _provider((_) async => http.Response('', 404)).delete(_tok, '1');
    await _provider((_) async => http.Response('', 204)).delete(_tok, '1');
    expect(
      () => _provider((_) async => http.Response('', 500)).delete(_tok, '1'),
      throwsA(isA<ProviderError>()),
    );
  });
}
