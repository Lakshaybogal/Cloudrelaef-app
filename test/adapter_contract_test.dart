import 'dart:typed_data';

import 'package:cloudrelaef/providers/dropbox.dart';
import 'package:cloudrelaef/providers/google_drive.dart';
import 'package:cloudrelaef/providers/http_util.dart' as h;
import 'package:cloudrelaef/providers/onedrive.dart';
import 'package:cloudrelaef/providers/storage_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sim_servers.dart';

final _tok = AccessToken(token: 'tok', expiresAt: DateTime.utc(2100));
const _cfg = OAuthClientConfig(clientId: 'cid');

Stream<List<int>> _bytes(List<int> b) => Stream.value(b);
Future<List<int>> _collect(Stream<List<int>> s) async => [
  for (final c in await s.toList()) ...c,
];

class _Case {
  _Case(this.name, this.make, {this.chunk, this.renameClash409 = true});
  final String name;
  final StorageProvider Function() make;

  /// Chunk size the adapter uploads with; null skips the large-file test.
  final int? chunk;

  /// Google Drive allows duplicate names, so there is no clash to test.
  final bool renameClash409;
}

void main() {
  setUp(() => h.sleeper = (_) async {});

  final cases = [
    _Case(
      'dropbox',
      () => DropboxProvider(_cfg, client: DropboxSim().client()),
      chunk: dropboxChunkSize,
    ),
    _Case(
      'onedrive',
      () => OneDriveProvider(_cfg, client: OneDriveSim().client()),
      chunk: onedriveChunkSize,
    ),
    _Case(
      'google',
      () => GoogleDriveProvider(_cfg, client: GoogleSim().client()),
      chunk: googleChunkSize,
      renameClash409: false,
    ),
  ];

  for (final c in cases) {
    group('contract: ${c.name}', () {
      late StorageProvider p;
      setUp(() => p = c.make());

      Future<RemoteFile> put(String name, List<int> data) => p.upload(
        _tok,
        name: name,
        size: data.length,
        mime: 'application/octet-stream',
        data: _bytes(data),
      );

      test('auth url carries state, redirect and an S256 challenge', () {
        final u = p.authUrl(
          state: 'st',
          redirectUri: 'http://127.0.0.1:5/',
          codeChallenge: 'ch',
        );
        final q = u.queryParameters;
        expect(q['state'], 'st');
        expect(q['redirect_uri'], 'http://127.0.0.1:5/');
        expect(q['code_challenge'], 'ch');
        expect(q['code_challenge_method'], 'S256');
        expect(q['client_id'], 'cid');
        expect(q['response_type'], 'code');
      });

      test('exchange and refresh produce usable tokens', () async {
        final t = await p.exchangeCode(
          code: 'c',
          redirectUri: 'r',
          verifier: 'v',
        );
        expect(t.refreshToken, isNotEmpty);
        expect(t.accountId, isNotEmpty);
        expect(t.displayName, contains('@'));
        expect((await p.refreshToken('rt')).token, 'at');
      });

      test('upload then download round-trips the bytes', () async {
        final f = await put('a.txt', [1, 2, 3, 4, 5]);
        expect(f.name, 'a.txt');
        expect(f.size, 5);
        expect(await _collect(p.download(_tok, f.remoteId)), [1, 2, 3, 4, 5]);
      });

      test('empty files work', () async {
        final f = await put('empty', []);
        expect(f.size, 0);
        expect(await _collect(p.download(_tok, f.remoteId)), isEmpty);
      });

      test('names with spaces and unicode survive', () async {
        final f = await put('my file é.txt', [9]);
        expect(f.name, 'my file é.txt');
      });

      test(
        'listing pages through every file and skips folders/deleted',
        () async {
          for (final n in ['1', '2', '3', '4', '5']) {
            await put('f$n', [1]);
          }
          final seen = <String>[];
          String? cursor;
          var pages = 0;
          do {
            final page = await p.listFiles(_tok, cursor: cursor);
            seen.addAll(page.files.map((f) => f.name));
            cursor = page.nextCursor;
            pages++;
          } while (cursor != null);
          expect(seen..sort(), ['f1', 'f2', 'f3', 'f4', 'f5']);
          expect(pages, greaterThan(1));
        },
      );

      test('quota reflects uploaded bytes', () async {
        await put('q', List.filled(40, 1));
        final q = await p.getQuota(_tok);
        expect(q.used, 40);
        expect(q.total, isNotNull);
      });

      test('rename changes the name and keeps the id', () async {
        final f = await put('old', [1]);
        final r = await p.rename(_tok, f.remoteId, 'new');
        expect(r.name, 'new');
        expect(r.remoteId, f.remoteId);
      });

      if (c.renameClash409) {
        test('rename onto an existing name is a 409', () async {
          await put('x', [1]);
          final y = await put('y', [1]);
          await expectLater(
            p.rename(_tok, y.remoteId, 'x'),
            throwsA(
              isA<ProviderError>().having((e) => e.status, 'status', 409),
            ),
          );
        });
      }

      test('delete removes the file; deleting again is fine', () async {
        final f = await put('d', [1]);
        await p.delete(_tok, f.remoteId);
        expect((await p.listFiles(_tok)).files, isEmpty);
        await p.delete(_tok, f.remoteId);
      });

      test('a body larger than declared is rejected', () async {
        await expectLater(
          p.upload(
            _tok,
            name: 'big',
            size: 1,
            mime: 'x/y',
            data: _bytes([1, 2]),
          ),
          throwsA(isA<ProviderError>()),
        );
      });

      test('a body shorter than declared is rejected', () async {
        await expectLater(
          p.upload(
            _tok,
            name: 'short',
            size: 5,
            mime: 'x/y',
            data: _bytes([1, 2]),
          ),
          throwsA(isA<ProviderError>()),
        );
      });

      if (c.chunk != null) {
        test(
          'a file just over one chunk uploads and downloads intact',
          () async {
            final size = c.chunk! + 10;
            final data = Uint8List(size);
            for (var i = 0; i < size; i += 4096) {
              data[i] = i % 251;
            }
            final f = await put('large.bin', data);
            expect(f.size, size);
            final back = await _collect(p.download(_tok, f.remoteId));
            expect(back.length, size);
            expect(back[4096], data[4096]);
            expect(back[size - 1], data[size - 1]);
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );
      }
    });
  }
}
