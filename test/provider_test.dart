import 'package:cloudrelaef/providers/registry.dart';
import 'package:cloudrelaef/providers/storage_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_provider.dart';

Stream<List<int>> bytes(List<int> b) => Stream.value(b);

Future<List<int>> collect(Stream<List<int>> s) async => [
  for (final chunk in await s.toList()) ...chunk,
];

void main() {
  final fake = FakeProvider(total: 20);
  final tok = AccessToken(token: 't', expiresAt: _never);

  test('registry resolves ids and rejects unknown ones', () {
    final r = ProviderRegistry([fake]);
    expect(r.get('fake'), same(fake));
    expect(r.ids, ['fake']);
    expect(() => r.get('nope'), throwsArgumentError);
  });

  test('upload then download returns the same bytes', () async {
    final f = await fake.upload(
      tok,
      name: 'a.txt',
      size: 7,
      mime: 'text/plain',
      data: bytes([1, 2, 3, 4, 5, 6, 7]),
    );
    expect(await collect(fake.download(tok, f.remoteId)), [
      1,
      2,
      3,
      4,
      5,
      6,
      7,
    ]);
    expect((await fake.getQuota(tok)).used, 7);
  });

  test('listing pages through all files', () async {
    for (final n in ['b', 'c']) {
      await fake.upload(tok, name: n, size: 1, mime: '', data: bytes([1]));
    }
    final seen = <String>[];
    String? cursor;
    do {
      final page = await fake.listFiles(tok, cursor: cursor);
      seen.addAll(page.files.map((f) => f.remoteId));
      cursor = page.nextCursor;
    } while (cursor != null);
    expect(seen.length, 3);
    expect(seen.toSet().length, 3);
  });

  test('rename clash is a 409', () async {
    final files = (await fake.listFiles(tok)).files;
    expect(
      () => fake.rename(tok, files[1].remoteId, files[0].name),
      throwsA(isA<ProviderError>().having((e) => e.status, 'status', 409)),
    );
  });

  test('quota exceeded is a 507 and delete frees space', () async {
    expect(
      () => fake.upload(
        tok,
        name: 'big',
        size: 19,
        mime: '',
        data: bytes(List.filled(19, 0)),
      ),
      throwsA(isA<ProviderError>().having((e) => e.status, 'status', 507)),
    );
    final files = (await fake.listFiles(tok)).files;
    await fake.delete(tok, files.first.remoteId);
    expect(
      () => fake.delete(tok, files.first.remoteId),
      throwsA(isA<ProviderError>()),
    );
  });
}

final _never = DateTime.utc(2100);
