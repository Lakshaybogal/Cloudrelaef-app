import 'package:cloudrelaef/data/db/database.dart';
import 'package:cloudrelaef/providers/storage_provider.dart';
import 'package:cloudrelaef/services/accounts.dart';
import 'package:cloudrelaef/services/files.dart';
import 'package:cloudrelaef/services/folders.dart';
import 'package:cloudrelaef/services/placement.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

void main() {
  late Harness h;
  late int accA;
  late int accB;

  setUp(() async {
    h = Harness();
    accA = await h.connect(h.a, 'a');
    accB = await h.connect(h.b, 'b');
  });
  tearDown(() => h.close());

  Future<FileEntry> up(String name, List<int> data, {int? folder}) =>
      h.files.upload(
        name: name,
        size: data.length,
        mime: 'text/plain',
        data: bytes(data),
        folderId: folder,
      );

  group('upload & placement', () {
    test('goes to the account with most free space, then balances', () async {
      final big = Harness(totalA: 100, totalB: 1000);
      final a = await big.connect(big.a, 'a');
      final b = await big.connect(big.b, 'b');
      final f = await big.files.upload(
        name: 'x',
        size: 50,
        mime: 'x/y',
        data: bytes(List.filled(50, 1)),
      );
      expect(f.accountId, b);
      expect(a, isNot(b));
      await big.close();
    });

    test('stale quota is refreshed before placing', () async {
      expect(
        (await h.accounts.list()).every((a) => a.quotaSyncedAt == null),
        isTrue,
      );
      await up('x', [1]);
      expect(
        (await h.accounts.list()).every((a) => a.quotaSyncedAt != null),
        isTrue,
      );
    });

    test('no capacity throws and uploads nothing', () async {
      await expectLater(
        h.files.upload(
          name: 'huge',
          size: 5000,
          mime: 'x/y',
          data: bytes(List.filled(5000, 1)),
        ),
        throwsA(isA<NoCapacityError>()),
      );
      expect(await h.files.list(), isEmpty);
    });

    test('accounts needing reauth are skipped', () async {
      await (h.db.update(
        h.db.linkedAccounts,
      )..where((t) => t.id.equals(accA))).write(
        const LinkedAccountsCompanion(status: Value(AccountStatus.needsReauth)),
      );
      final f = await up('x', [1]);
      expect(f.accountId, accB);
    });

    test('upload into a folder; download returns the bytes', () async {
      final folder = await h.folders.create('docs');
      final f = await up('a.txt', [1, 2, 3], folder: folder);
      expect(f.folderId, folder);
      expect(await collect(await h.files.download(f.id)), [1, 2, 3]);
    });
  });

  group('sync', () {
    test('indexes provider files, then removes vanished ones', () async {
      final tok = AccessToken(token: 't', expiresAt: DateTime.utc(2100));
      final r1 = await h.a.upload(
        tok,
        name: 'one',
        size: 1,
        mime: 'x/y',
        data: bytes([1]),
      );
      await h.a.upload(
        tok,
        name: 'two',
        size: 1,
        mime: 'x/y',
        data: bytes([2]),
      );
      await h.a.upload(
        tok,
        name: 'three',
        size: 1,
        mime: 'x/y',
        data: bytes([3]),
      );
      var res = await h.sync.syncAccount(accA);
      expect(res.seen, 3);
      expect((await h.files.list(accountId: accA)).length, 3);

      await h.a.delete(tok, r1.remoteId);
      res = await h.sync.syncAccount(accA);
      expect(res.removed, 1);
      expect((await h.files.list(accountId: accA)).length, 2);
    });

    test('keeps folder placement and trash state across syncs', () async {
      final tok = AccessToken(token: 't', expiresAt: DateTime.utc(2100));
      await h.a.upload(
        tok,
        name: 'one',
        size: 1,
        mime: 'x/y',
        data: bytes([1]),
      );
      await h.a.upload(
        tok,
        name: 'two',
        size: 1,
        mime: 'x/y',
        data: bytes([2]),
      );
      await h.sync.syncAccount(accA);
      final files = await h.files.list(accountId: accA);
      final folder = await h.folders.create('keep');
      await h.files.moveToFolder(files[0].id, folder);
      await h.files.trash(files[1].id);
      await h.sync.syncAccount(accA);
      expect((await h.files.get(files[0].id)).folderId, folder);
      expect((await h.files.get(files[1].id)).trashedAt, isNotNull);
    });

    test('stores quota and a history row at most every 3 hours', () async {
      await h.sync.refreshQuota(accA);
      await h.sync.refreshQuota(accA);
      expect((await h.db.select(h.db.quotaSnapshots).get()).length, 1);
      h.now = h.now.add(const Duration(hours: 4));
      await h.sync.refreshQuota(accA);
      expect((await h.db.select(h.db.quotaSnapshots).get()).length, 2);
      final acc = (await h.accounts.list()).firstWhere((a) => a.id == accA);
      expect(acc.quotaTotal, 1000);
    });

    test('syncAll isolates a failing account and skips reauth ones', () async {
      await (h.db.update(
        h.db.linkedAccounts,
      )..where((t) => t.id.equals(accB))).write(
        const LinkedAccountsCompanion(status: Value(AccountStatus.needsReauth)),
      );
      final out = await h.sync.syncAll();
      expect(out.keys, [accA]);
    });
  });

  group('trash', () {
    test(
      'trash hides, restore brings back, purge deletes at the cloud',
      () async {
        final f = await up('x', [1, 2]);
        await h.files.trash(f.id);
        expect(await h.files.list(), isEmpty);
        expect((await h.files.list(trashed: true)).single.id, f.id);
        await h.files.restore(f.id);
        expect((await h.files.list()).single.id, f.id);

        await expectLater(h.files.purge(f.id), throwsA(isA<FileException>()));
        await h.files.trash(f.id);
        await h.files.purge(f.id);
        expect(await h.files.list(trashed: true), isEmpty);
        final acc = f.accountId == accA ? h.a : h.b;
        expect(
          (await acc.listFiles(
            AccessToken(token: 't', expiresAt: DateTime.utc(2100)),
          )).files,
          isEmpty,
        );
      },
    );

    test('purge keeps the entry when the cloud refuses', () async {
      final f = await up('x', [1]);
      await h.files.trash(f.id);
      final tok = AccessToken(token: 't', expiresAt: DateTime.utc(2100));
      final acc = f.accountId == accA ? h.a : h.b;
      await acc.delete(
        tok,
        f.remoteId,
      ); // already gone at the cloud -> fake 404s
      await expectLater(h.files.purge(f.id), throwsA(isA<ProviderError>()));
      expect((await h.files.list(trashed: true)).length, 1);
    });

    test('restore drops a folder that no longer exists', () async {
      final folder = await h.folders.create('tmp');
      final f = await up('x', [1], folder: folder);
      await h.files.trash(f.id);
      await h.db.delete(h.db.folders).go();
      await h.files.restore(f.id);
      expect((await h.files.get(f.id)).folderId, isNull);
    });
  });

  group('rename, search', () {
    test('rename updates cloud and index; clash surfaces as 409', () async {
      final solo = Harness();
      await solo.connect(solo.a, 'a');
      Future<FileEntry> put(String n) =>
          solo.files.upload(name: n, size: 1, mime: 'x/y', data: bytes([1]));
      final f = await put('old');
      await put('other');
      await solo.files.rename(f.id, 'new');
      expect((await solo.files.get(f.id)).name, 'new');
      await expectLater(
        solo.files.rename(f.id, 'other'),
        throwsA(isA<ProviderError>().having((e) => e.status, 'status', 409)),
      );
      await solo.close();
    });

    test('search is case-insensitive and escapes wildcards', () async {
      await up('Report_2026.txt', [1]);
      await up('reportX2026.txt', [1]);
      await up('notes.txt', [1]);
      expect((await h.files.list(query: 'REPORT')).length, 2);
      expect((await h.files.list(query: 'report_')).map((f) => f.name), [
        'Report_2026.txt',
      ]);
      expect(await h.files.list(query: '%'), isEmpty);
    });

    test('folder and top-level filters', () async {
      final folder = await h.folders.create('f');
      await up('in', [1], folder: folder);
      await up('out', [1]);
      expect((await h.files.list(folderId: folder)).single.name, 'in');
      expect((await h.files.list(topLevelOnly: true)).single.name, 'out');
    });
  });

  group('transfer', () {
    test('move repoints the same row and deletes the original', () async {
      final f = await up('x', [1, 2, 3]);
      final target = f.accountId == accA ? accB : accA;
      final res = await h.files.transfer(f.id, target);
      expect(res.fileId, f.id);
      expect(res.sourceDeleted, isTrue);
      final moved = await h.files.get(f.id);
      expect(moved.accountId, target);
      expect(await collect(await h.files.download(f.id)), [1, 2, 3]);
      final tok = AccessToken(token: 't', expiresAt: DateTime.utc(2100));
      final src = f.accountId == accA ? h.a : h.b;
      expect((await src.listFiles(tok)).files, isEmpty);
    });

    test('copy keeps the original and adds a row', () async {
      final f = await up('x', [1]);
      final target = f.accountId == accA ? accB : accA;
      final res = await h.files.transfer(f.id, target, keepOriginal: true);
      expect(res.fileId, isNot(f.id));
      expect((await h.files.list()).length, 2);
    });

    test('same account, inactive target and full target are refused', () async {
      final f = await up('x', [1]);
      await expectLater(
        h.files.transfer(f.id, f.accountId),
        throwsA(isA<FileException>()),
      );
      final other = f.accountId == accA ? accB : accA;
      await (h.db.update(
        h.db.linkedAccounts,
      )..where((t) => t.id.equals(other))).write(
        const LinkedAccountsCompanion(status: Value(AccountStatus.needsReauth)),
      );
      await expectLater(
        h.files.transfer(f.id, other),
        throwsA(isA<FileException>()),
      );
      await (h.db.update(
        h.db.linkedAccounts,
      )..where((t) => t.id.equals(other))).write(
        const LinkedAccountsCompanion(
          status: Value(AccountStatus.active),
          quotaTotal: Value(1),
          quotaUsed: Value(1),
        ),
      );
      await h.db.customStatement('UPDATE files SET size = 5');
      await expectLater(
        h.files.transfer(f.id, other),
        throwsA(isA<NoCapacityError>()),
      );
    });

    test('keeps the folder and reports a failed source delete', () async {
      final folder = await h.folders.create('f');
      final f = await up('x', [1], folder: folder);
      final src = f.accountId == accA ? h.a : h.b;
      src.failDeletes = true;
      final target = f.accountId == accA ? accB : accA;
      final res = await h.files.transfer(f.id, target);
      expect(res.sourceDeleted, isFalse);
      final moved = await h.files.get(f.id);
      expect(moved.accountId, target);
      expect(moved.folderId, folder);
    });
  });

  group('folders', () {
    late FolderService fs;
    setUp(() => fs = h.folders);

    test(
      'names are trimmed, validated and unique per parent (case-insensitive)',
      () async {
        final a = await fs.create('  Docs ');
        expect((await fs.list()).single.name, 'Docs');
        await expectLater(fs.create('docs'), throwsA(isA<FolderException>()));
        await expectLater(fs.create(''), throwsA(isA<FolderException>()));
        await expectLater(fs.create('a/b'), throwsA(isA<FolderException>()));
        await fs.create(
          'docs',
          parentId: a,
        ); // same name under another parent is fine
      },
    );

    test('rename and move; cycles are refused', () async {
      final a = await fs.create('a');
      final b = await fs.create('b', parentId: a);
      final c = await fs.create('c', parentId: b);
      await expectLater(fs.move(a, c), throwsA(isA<FolderException>()));
      await expectLater(fs.move(a, a), throwsA(isA<FolderException>()));
      await fs.move(c, null);
      await fs.rename(c, 'C2');
      expect((await fs.list()).firstWhere((f) => f.id == c).name, 'C2');
      await expectLater(fs.move(b, null), completes);
    });

    test('move onto a name clash is refused', () async {
      await fs.create('x');
      final p = await fs.create('p');
      final inner = await fs.create('x', parentId: p);
      await expectLater(fs.move(inner, null), throwsA(isA<FolderException>()));
    });

    test('only empty folders can be deleted', () async {
      final a = await fs.create('a');
      final b = await fs.create('b', parentId: a);
      await expectLater(fs.delete(a), throwsA(isA<FolderException>()));
      await up('x', [1], folder: b);
      await expectLater(fs.delete(b), throwsA(isA<FolderException>()));
      await h.db.delete(h.db.files).go();
      await fs.delete(b);
      await fs.delete(a);
      expect(await fs.list(), isEmpty);
    });
  });
}
