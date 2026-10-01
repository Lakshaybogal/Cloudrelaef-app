import 'dart:convert';

import 'package:cloudrelaef/providers/dropbox.dart';
import 'package:cloudrelaef/providers/http_util.dart' as h;
import 'package:cloudrelaef/providers/onedrive.dart';
import 'package:cloudrelaef/providers/storage_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/sim_servers.dart';

const _cfg = OAuthClientConfig(clientId: 'cid');
final _tok = AccessToken(token: 'tok', expiresAt: DateTime.utc(2100));

void main() {
  setUp(() => h.sleeper = (_) async {});

  group('OneDrive', () {
    test('refresh returns the rotated refresh token', () async {
      final p = OneDriveProvider(_cfg, client: OneDriveSim().client());
      expect((await p.refreshToken('old')).newRefreshToken, 'rt-new');
    });

    test('asks for offline_access and account selection', () {
      final q = OneDriveProvider(_cfg)
          .authUrl(state: 's', redirectUri: 'r', codeChallenge: 'c')
          .queryParameters;
      expect(q['scope'], contains('offline_access'));
      expect(q['scope'], contains('Files.ReadWrite.AppFolder'));
      expect(q['prompt'], 'select_account');
    });

    test('forbidden characters in names become underscores', () async {
      final sim = OneDriveSim();
      final p = OneDriveProvider(_cfg, client: sim.client());
      final f = await p.upload(
        _tok,
        name: 'a:b*c?.txt',
        size: 1,
        mime: 'x/y',
        data: Stream.value([1]),
      );
      expect(f.name, 'a_b_c_.txt');
    });

    test('invalid_grant means reauth; other 400s are plain errors', () async {
      final revoked = OneDriveProvider(
        _cfg,
        client: MockClient(
          (_) async => jsonResp({'error': 'invalid_grant'}, 400),
        ),
      );
      expect(() => revoked.refreshToken('r'), throwsA(isA<ReauthRequired>()));
      final other = OneDriveProvider(
        _cfg,
        client: MockClient(
          (_) async => jsonResp({'error': 'invalid_client'}, 400),
        ),
      );
      expect(
        () => other.refreshToken('r'),
        throwsA(
          isA<ProviderError>().having(
            (e) => e is ReauthRequired,
            'reauth',
            false,
          ),
        ),
      );
    });

    test('listing rejects a cursor that is not a Graph url', () {
      final p = OneDriveProvider(_cfg, client: OneDriveSim().client());
      expect(
        () => p.listFiles(_tok, cursor: 'https://evil.example/steal'),
        throwsA(isA<ProviderError>()),
      );
    });
  });

  group('Dropbox', () {
    test('requests offline access and the app-folder scopes', () {
      final q = DropboxProvider(_cfg)
          .authUrl(state: 's', redirectUri: 'r', codeChallenge: 'c')
          .queryParameters;
      expect(q['token_access_type'], 'offline');
      expect(q['scope'], contains('files.content.write'));
    });

    test('non-ASCII names are escaped in the API-arg header', () async {
      String? header;
      final p = DropboxProvider(
        _cfg,
        client: MockClient((req) async {
          header = req.headers['Dropbox-API-Arg'];
          return jsonResp({
            '.tag': 'file',
            'id': 'id:1',
            'name': 'é.txt',
            'size': 1,
            'path_display': '/é.txt',
          });
        }),
      );
      await p.upload(
        _tok,
        name: 'é.txt',
        size: 1,
        mime: 'x/y',
        data: Stream.value([1]),
      );
      expect(header!.codeUnits.every((c) => c < 128), isTrue);
      expect(jsonDecode(header!)['path'], '/é.txt');
    });

    test('mime type is guessed from the name', () async {
      final sim = DropboxSim();
      final p = DropboxProvider(_cfg, client: sim.client());
      final f = await p.upload(
        _tok,
        name: 'pic.png',
        size: 1,
        mime: 'x/y',
        data: Stream.value([1]),
      );
      expect(f.mime, 'image/png');
    });

    test('an upload name clash is auto-renamed, not overwritten', () async {
      final sim = DropboxSim();
      final p = DropboxProvider(_cfg, client: sim.client());
      await p.upload(
        _tok,
        name: 'a',
        size: 1,
        mime: 'x/y',
        data: Stream.value([1]),
      );
      final second = await p.upload(
        _tok,
        name: 'a',
        size: 1,
        mime: 'x/y',
        data: Stream.value([2]),
      );
      expect(second.name, 'a (1)');
      expect(sim.store.items.length, 2);
    });

    test('invalid_grant means reauth', () async {
      final p = DropboxProvider(
        _cfg,
        client: MockClient(
          (_) async => http.Response('{"error":"invalid_grant"}', 400),
        ),
      );
      expect(() => p.refreshToken('r'), throwsA(isA<ReauthRequired>()));
    });

    test('no allocation means unlimited', () async {
      final p = DropboxProvider(
        _cfg,
        client: MockClient(
          (_) async => jsonResp({'used': 5, 'allocation': {}}),
        ),
      );
      final q = await p.getQuota(_tok);
      expect(q.total, isNull);
      expect(q.used, 5);
    });
  });
}
