import 'dart:io';
import 'dart:typed_data';

import 'package:cloudrelaef/backup/backup_service.dart';
import 'package:cloudrelaef/backup/crypto.dart';
import 'package:cloudrelaef/backup/key_store.dart';
import 'package:cloudrelaef/backup/naming.dart';
import 'package:cloudrelaef/backup/restore_service.dart';
import 'package:cloudrelaef/data/db/database_host.dart';
import 'package:cloudrelaef/data/secure/secret_store.dart';
import 'package:cloudrelaef/providers/registry.dart';
import 'package:cloudrelaef/providers/storage_provider.dart';
import 'package:cloudrelaef/services/accounts.dart';
import 'package:cloudrelaef/services/settings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

final _tok = AccessToken(token: 't', expiresAt: DateTime.utc(2100));

void main() {
  late Directory tmp;
  late Harness d1; // the old device
  late Uint8List key;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('cr_restore_test');
    d1 = Harness(totalA: 50000000, totalB: 50000000);
    await d1.connect(d1.a, 'a');
    await d1.connect(d1.b, 'b');
    key = (await BackupKeyStore(d1.secrets).ensure()).key;
  });
  tearDown(() async {
    await d1.close();
    await tmp.delete(recursive: true);
  });

  Future<List<CloudBackupResult>> backup(Harness h) => BackupService(
    db: h.db,
    accounts: h.accounts,
    registry: h.registry,
    keys: BackupKeyStore(h.secrets),
    settings: SettingsStore(h.db),
    tempDir: tmp,
    now: () => h.now,
  ).backupNow();

  /// A fresh device: empty file database, secrets, same clouds. Only cloud A
  /// is connected, as a user would do first.
  Future<
    ({
      DatabaseHost host,
      InMemorySecretStore secrets,
      RestoreService svc,
      AccountService accounts,
    })
  >
  newDevice({bool connectA = true}) async {
    final host = await DatabaseHost.open(
      File('${tmp.path}/device2/cloudrelaef.sqlite'),
    );
    final secrets = InMemorySecretStore();
    final registry = ProviderRegistry([d1.a, d1.b]);
    final accounts = AccountService(host.db, secrets, registry);
    if (connectA) {
      await accounts.add(
        d1.a.id,
        await d1.a.exchangeCode(code: 'a', redirectUri: 'r', verifier: 'v'),
      );
    }
    return (
      host: host,
      secrets: secrets,
      accounts: accounts,
      svc: RestoreService(
        host: host,
        secrets: secrets,
        registry: registry,
        tempDir: Directory('${tmp.path}/work'),
      ),
    );
  }

  test('full round trip onto a new device', () async {
    // Old device: some files, folders, a backup.
    final folder = await d1.folders.create('Trips');
    final f = await d1.files.upload(
      name: 'a.txt',
      size: 3,
      mime: 'text/plain',
      data: bytes([1, 2, 3]),
      folderId: folder,
    );
    await d1.files.trash(
      (await d1.files.upload(
        name: 'old.txt',
        size: 1,
        mime: 'x/y',
        data: bytes([9]),
      )).id,
    );
    expect((await backup(d1)).every((r) => r.ok), isTrue);

    final d2 = await newDevice();
    final out = await d2.svc.restoreLatest(accounts: d2.accounts, key: key);
    final db = d2.host.db;

    expect(out.snapshotCounter, 1);
    // Index, folders and trash state came back.
    final files = await db.select(db.files).get();
    expect(files.map((e) => e.name).toSet(), {'a.txt', 'old.txt'});
    expect(files.firstWhere((e) => e.name == 'a.txt').folderId, isNotNull);
    expect(files.firstWhere((e) => e.name == 'old.txt').trashedAt, isNotNull);
    expect((await db.select(db.folders).get()).single.name, 'Trips');
    expect(f.id, isNotNull);

    // The cloud connected on this device works; the other must reconnect.
    final accounts = await db.select(db.linkedAccounts).get();
    final a = accounts.firstWhere((x) => x.provider == 'fakeA');
    final b = accounts.firstWhere((x) => x.provider == 'fakeB');
    expect(a.status, AccountStatus.active);
    expect(b.status, AccountStatus.needsReauth);
    expect(out.accountsNeedingReauth, 1);
    expect(await d2.secrets.read(SecretStore.refreshTokenKey(a.id)), isNotNull);
    expect(await d2.secrets.read(SecretStore.refreshTokenKey(b.id)), isNull);

    // Key kept, new device id, counter continues.
    expect(await BackupKeyStore(d2.secrets).load(), key);
    final s2 = SettingsStore(db);
    expect(await s2.getInt(SettingKeys.backupCounter), 1);
    expect(
      await s2.get(SettingKeys.deviceId),
      isNot(await SettingsStore(d1.db).get(SettingKeys.deviceId)),
    );
    await d2.host.close();
  });

  test('the next backup from the restored device continues the sequence without a conflict', () async {
    await backup(d1);
    final d2 = await newDevice();
    await d2.svc.restoreLatest(accounts: d2.accounts, key: key);
    final db = d2.host.db;
    final registry = ProviderRegistry([d1.a, d1.b]);
    final accounts = AccountService(db, d2.secrets, registry);
    final svc = BackupService(
      db: db,
      accounts: accounts,
      registry: registry,
      keys: BackupKeyStore(d2.secrets),
      settings: SettingsStore(db),
      tempDir: tmp,
    );
    final res = await svc.backupNow();
    expect(res.where((r) => r.ok).length, 1); // only cloud A is connected here
    final names = (await d1.a.listFiles(_tok)).files
        .map((f) => f.name)
        .where(isBackupFileName)
        .toList();
    expect(names.length, 2);
    await d2.host.close();
  });

  test('the wrong key is refused and nothing is replaced', () async {
    await d1.files.upload(
      name: 'a.txt',
      size: 1,
      mime: 'x/y',
      data: bytes([1]),
    );
    await backup(d1);
    final d2 = await newDevice();
    await expectLater(
      d2.svc.restoreLatest(accounts: d2.accounts, key: RecoveryKey.generate()),
      throwsA(isA<BackupCryptoException>()),
    );
    expect(await d2.host.db.select(d2.host.db.files).get(), isEmpty);
    expect(
      await d2.host.db.select(d2.host.db.linkedAccounts).get(),
      hasLength(1),
    );
    await d2.host.close();
  });

  test('no backup anywhere is a clear error', () async {
    final d2 = await newDevice();
    await expectLater(
      d2.svc.restoreLatest(accounts: d2.accounts, key: key),
      throwsA(isA<NoBackupFound>()),
    );
    await d2.host.close();
  });

  test('picks the highest counter across clouds', () async {
    await backup(d1);
    await d1.files.upload(
      name: 'later.txt',
      size: 1,
      mime: 'x/y',
      data: bytes([1]),
    );
    await backup(d1); // counter 2 on both
    // Make cloud A's newest unreadable so only B has counter 2.
    final tok = _tok;
    final filesA = (await d1.a.listFiles(tok)).files
        .where((f) => isBackupFileName(f.name));
    for (final f in filesA) {
      if (BackupFileName.parse(f.name)!.counter == 2) {
        await d1.a.delete(tok, f.remoteId);
      }
    }
    final d2 = await newDevice();
    // Connect B too so its snapshots are visible.
    await d2.accounts.add(
      d1.b.id,
      await d1.b.exchangeCode(code: 'b', redirectUri: 'r', verifier: 'v'),
    );
    final out = await d2.svc.restoreLatest(accounts: d2.accounts, key: key);
    expect(out.snapshotCounter, 2);
    expect(
      (await d2.host.db.select(d2.host.db.files).get()).map((f) => f.name),
      contains('later.txt'),
    );
    await d2.host.close();
  });

  test('a corrupt newest snapshot falls back to an older one', () async {
    await d1.files.upload(
      name: 'a.txt',
      size: 1,
      mime: 'x/y',
      data: bytes([1]),
    );
    await backup(d1); // counter 1
    // Counter 2 is garbage with a valid name.
    final garbage = BackupFileName(counter: 2, deviceId: 'deadbeef').fileName;
    await d1.a.upload(
      _tok,
      name: garbage,
      size: 4,
      mime: 'x/y',
      data: bytes([1, 2, 3, 4]),
    );
    final d2 = await newDevice();
    final out = await d2.svc.restoreLatest(accounts: d2.accounts, key: key);
    expect(out.snapshotCounter, 1);
    expect(
      (await d2.host.db.select(d2.host.db.files).get()).single.name,
      'a.txt',
    );
    await d2.host.close();
  });

  test(
    'a snapshot from a newer schema is refused with a helpful message',
    () async {
      final crypto = BackupCrypto();
      final blob = await crypto.seal(
        key: key,
        header: {
          'schema_version': 999,
          'snapshot_id': 'x',
          'counter': 5,
          'device_id': 'abcdef01',
        },
        plaintext: [1, 2, 3],
      );
      await d1.a.upload(
        _tok,
        name: BackupFileName(counter: 5, deviceId: 'abcdef01').fileName,
        size: blob.length,
        mime: 'x/y',
        data: Stream.value(blob),
      );
      final d2 = await newDevice();
      await expectLater(
        d2.svc.restoreLatest(accounts: d2.accounts, key: key),
        throwsA(
          isA<BackupCryptoException>().having(
            (e) => e.message,
            'message',
            contains('newer version'),
          ),
        ),
      );
      await d2.host.close();
    },
  );

  test('restored database works with the services (end to end)', () async {
    await d1.files.upload(
      name: 'doc.txt',
      size: 2,
      mime: 'x/y',
      data: bytes([4, 2]),
    );
    await backup(d1);
    final d2 = await newDevice();
    await d2.svc.restoreLatest(accounts: d2.accounts, key: key);
    final h2 = Harness(providerA: d1.a, providerB: d1.b, database: d2.host.db);
    // Re-point secrets: the harness has its own store, so reuse the device's.
    final accounts = AccountService(d2.host.db, d2.secrets, h2.registry);
    final entry = (await h2.files.list()).single;
    expect(entry.name, 'doc.txt');
    final restoredAcc = await d2.host.db
        .select(d2.host.db.linkedAccounts)
        .get();
    expect(accounts, isNotNull);
    expect(restoredAcc.length, 2);
    // The file's cloud copy is still downloadable through the original provider.
    final owner =
        restoredAcc.firstWhere((a) => a.id == entry.accountId).provider ==
            'fakeA'
        ? d1.a
        : d1.b;
    expect(await collect(owner.download(_tok, entry.remoteId)), [4, 2]);
    await d2.host.close();
  });
}
