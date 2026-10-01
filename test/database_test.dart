import 'package:cloudrelaef/data/db/database.dart';
import 'package:cloudrelaef/data/secure/secret_store.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  Future<int> addAccount([String pid = 'a1']) => db
      .into(db.linkedAccounts)
      .insert(
        LinkedAccountsCompanion.insert(
          provider: 'fake',
          providerAccountId: pid,
          displayName: 'Fake',
        ),
      );

  Future<int> addFile(int account, String remote, {int? folder}) => db
      .into(db.files)
      .insert(
        FilesCompanion.insert(
          accountId: account,
          remoteId: remote,
          name: remote,
          indexedAt: DateTime.utc(2026),
          folderId: Value(folder),
        ),
      );

  test('account defaults and uniqueness', () async {
    final id = await addAccount();
    final row = await (db.select(
      db.linkedAccounts,
    )..where((t) => t.id.equals(id))).getSingle();
    expect(row.status, 'active');
    expect(row.quotaUsed, 0);
    expect(() => addAccount(), throwsA(isA<Exception>()));
  });

  test('file (account, remoteId) is unique', () async {
    final a = await addAccount();
    await addFile(a, 'r1');
    expect(() => addFile(a, 'r1'), throwsA(isA<Exception>()));
  });

  test('removing an account removes its files', () async {
    final a = await addAccount();
    await addFile(a, 'r1');
    await (db.delete(db.linkedAccounts)..where((t) => t.id.equals(a))).go();
    expect(await db.select(db.files).get(), isEmpty);
  });

  test('deleting a folder keeps files at top level', () async {
    final a = await addAccount();
    final f = await db
        .into(db.folders)
        .insert(FoldersCompanion.insert(name: 'docs'));
    await addFile(a, 'r1', folder: f);
    await (db.delete(db.folders)..where((t) => t.id.equals(f))).go();
    final file = await db.select(db.files).getSingle();
    expect(file.folderId, isNull);
  });

  test('settings round-trip', () async {
    await db
        .into(db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: 'k', value: 'v1'),
        );
    await db
        .into(db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: 'k', value: 'v2'),
        );
    expect((await db.select(db.appSettings).getSingle()).value, 'v2');
  });

  test('secrets are not part of the database schema', () {
    final cols = db.linkedAccounts.$columns.map((c) => c.name).join(',');
    expect(cols.contains('token'), isFalse);
  });

  test('secret store contract (in memory)', () async {
    final s = InMemorySecretStore();
    final k = SecretStore.refreshTokenKey(1);
    expect(await s.read(k), isNull);
    await s.write(k, 'abc');
    expect(await s.read(k), 'abc');
    await s.delete(k);
    expect(await s.read(k), isNull);
  });
}
