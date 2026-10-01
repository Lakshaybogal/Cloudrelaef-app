import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloudrelaef/backup/backup_service.dart';
import 'package:cloudrelaef/backup/crypto.dart';
import 'package:cloudrelaef/backup/key_store.dart';
import 'package:cloudrelaef/backup/naming.dart';
import 'package:cloudrelaef/backup/snapshot.dart';
import 'package:cloudrelaef/providers/storage_provider.dart';
import 'package:cloudrelaef/services/settings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_provider.dart';
import 'support/harness.dart';

final _tok = AccessToken(token: 't', expiresAt: DateTime.utc(2100));

void main() {
  group('recovery key', () {
    test('round-trips and tolerates formatting', () {
      final key = RecoveryKey.generate();
      final code = RecoveryKey.encode(key);
      expect(RecoveryKey.decode(code), key);
      expect(RecoveryKey.decode(code.toLowerCase().replaceAll('-', ' ')), key);
      expect(
        RegExp(r'^([A-Z2-7]{1,4}-)+[A-Z2-7]{1,4}$').hasMatch(code),
        isTrue,
      );
    });

    test('detects a typo and wrong lengths', () {
      final code = RecoveryKey.encode(RecoveryKey.generate());
      final typo = '${code[0] == 'A' ? 'B' : 'A'}${code.substring(1)}';
      expect(
        () => RecoveryKey.decode(typo),
        throwsA(isA<BackupCryptoException>()),
      );
      expect(
        () => RecoveryKey.decode('ABCD-EFGH'),
        throwsA(isA<BackupCryptoException>()),
      );
      expect(
        () => RecoveryKey.decode('1111-1111'),
        throwsA(isA<BackupCryptoException>()),
      );
    });

    test('keys are random', () {
      expect(RecoveryKey.generate(), isNot(RecoveryKey.generate()));
    });
  });

  group('crypto', () {
    final crypto = BackupCrypto();
    final key = RecoveryKey.generate();
    final plain = utf8.encode('hello backup');

    test('seal/open round-trips and exposes the header', () async {
      final blob = await crypto.seal(
        key: key,
        header: {'a': 1},
        plaintext: plain,
      );
      final r = await crypto.open(key: key, blob: blob);
      expect(r.plaintext, plain);
      expect(r.header['a'], 1);
      expect(BackupCrypto.peekHeader(blob)['a'], 1);
    });

    test('nonce is fresh each time', () async {
      final a = await crypto.seal(key: key, header: {}, plaintext: plain);
      final b = await crypto.seal(key: key, header: {}, plaintext: plain);
      expect(a, isNot(b));
    });

    test('wrong key is refused', () async {
      final blob = await crypto.seal(key: key, header: {}, plaintext: plain);
      await expectLater(
        crypto.open(key: RecoveryKey.generate(), blob: blob),
        throwsA(isA<BackupCryptoException>()),
      );
    });

    test('tampering with ciphertext or header is detected', () async {
      final blob = await crypto.seal(
        key: key,
        header: {'counter': 1},
        plaintext: plain,
      );
      final flipped = Uint8List.fromList(blob)..[blob.length - 20] ^= 1;
      await expectLater(
        crypto.open(key: key, blob: flipped),
        throwsA(isA<BackupCryptoException>()),
      );
      final headerEdit = Uint8List.fromList(blob);
      final i = headerEdit.indexOf('1'.codeUnitAt(0), 8);
      headerEdit[i] = '2'.codeUnitAt(0); // counter 1 -> 2
      await expectLater(
        crypto.open(key: key, blob: headerEdit),
        throwsA(isA<BackupCryptoException>()),
      );
    });

    test('garbage and truncated files are rejected cleanly', () async {
      await expectLater(
        crypto.open(key: key, blob: Uint8List.fromList([1, 2, 3])),
        throwsA(isA<BackupCryptoException>()),
      );
      final blob = await crypto.seal(key: key, header: {}, plaintext: plain);
      await expectLater(
        crypto.open(key: key, blob: blob.sublist(0, 20)),
        throwsA(isA<BackupCryptoException>()),
      );
      await expectLater(
        crypto.open(key: key, blob: Uint8List(64)),
        throwsA(isA<BackupCryptoException>()),
      );
    });
  });

  group('file names', () {
    test('round trip and rejection', () {
      final n = BackupFileName(counter: 42, deviceId: 'abcdef01');
      expect(n.fileName, 'cloudrelaef-backup-0000000042-abcdef01.crb');
      final p = BackupFileName.parse(n.fileName)!;
      expect(p.counter, 42);
      expect(p.deviceId, 'abcdef01');
      expect(BackupFileName.parse('holiday.jpg'), isNull);
      expect(BackupFileName.parse('cloudrelaef-backup-42-abc.crb'), isNull);
      expect(isBackupFileName(n.fileName), isTrue);
      expect(isBackupFileName('notes.crb'), isFalse);
    });
  });

  group('backup service', () {
    late Harness h;
    late int accA;
    late int accB;
    late Directory tmp;
    late BackupService svc;

    BackupService build(Harness h) => BackupService(
      db: h.db,
      accounts: h.accounts,
      registry: h.registry,
      keys: BackupKeyStore(h.secrets),
      settings: SettingsStore(h.db),
      tempDir: tmp,
      now: () => h.now,
    );

    Future<List<RemoteFile>> remote(FakeProvider provider) async {
      final out = <RemoteFile>[];
      String? cursor;
      do {
        final page = await provider.listFiles(_tok, cursor: cursor);
        out.addAll(page.files.where((f) => isBackupFileName(f.name)));
        cursor = page.nextCursor;
      } while (cursor != null);
      return out;
    }

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('cr_backup_test');
      h = Harness(totalA: 50000000, totalB: 50000000);
      accA = await h.connect(h.a, 'a');
      accB = await h.connect(h.b, 'b');
      svc = build(h);
      await BackupKeyStore(h.secrets).ensure();
    });
    tearDown(() async {
      await h.close();
      await tmp.delete(recursive: true);
    });

    test('refuses to run without a key', () async {
      final fresh = Harness(totalA: 50000000, totalB: 50000000);
      await fresh.connect(fresh.a, 'a');
      await expectLater(
        build(fresh).backupNow(),
        throwsA(isA<BackupNotSetUp>()),
      );
      await fresh.close();
    });

    test(
      'writes the same snapshot to every cloud and records the runs',
      () async {
        final res = await svc.backupNow();
        expect(res.map((r) => r.ok), [true, true]);
        final a = await remote(h.a);
        final b = await remote(h.b);
        expect(a.single.name, b.single.name);
        expect(BackupFileName.parse(a.single.name)!.counter, 1);
        expect((await h.db.select(h.db.backupRuns).get()).length, 2);
        expect(await svc.lastSuccess(), isNotNull);
      },
    );

    test('snapshot opens with the key and contains no credentials', () async {
      await h.files.upload(
        name: 'f.txt',
        size: 1,
        mime: 'x/y',
        data: bytes([1]),
      );
      await svc.backupNow();
      final snap = (await remote(h.a)).single;
      final blob = Uint8List.fromList(
        await collect(h.a.download(_tok, snap.remoteId)),
      );
      final key = (await BackupKeyStore(h.secrets).load())!;
      final opened = await SnapshotCodec().open(
        blob: blob,
        key: key,
        tempDir: tmp,
        supportedSchema: h.db.schemaVersion,
      );
      final raw = await opened.file.readAsBytes();
      for (final secret in ['refresh-a', 'refresh-b']) {
        expect(
          latin1.decode(raw, allowInvalid: true).contains(secret),
          isFalse,
        );
      }
      expect(raw.length, greaterThan(1000));
      expect(opened.header['schema_version'], h.db.schemaVersion);
    });

    test('counter increases per run', () async {
      await svc.backupNow();
      await svc.backupNow();
      final counters = (await remote(
        h.a,
      )).map((f) => BackupFileName.parse(f.name)!.counter).toList()..sort();
      expect(counters, [1, 2]);
    });

    test(
      'retention keeps the newest N and never deletes the new one',
      () async {
        await SettingsStore(h.db).setInt(SettingKeys.backupKeep, 3);
        for (var i = 0; i < 6; i++) {
          await svc.backupNow();
        }
        final counters = (await remote(
          h.a,
        )).map((f) => BackupFileName.parse(f.name)!.counter).toList()..sort();
        expect(counters, [4, 5, 6]);
      },
    );

    test('one failing cloud does not fail the others', () async {
      h.b.failUploads = true;
      final res = await svc.backupNow();
      expect(res.firstWhere((r) => r.accountId == accA).ok, isTrue);
      final bad = res.firstWhere((r) => r.accountId == accB);
      expect(bad.ok, isFalse);
      expect(bad.error, isNotNull);
      expect(await remote(h.a), hasLength(1));
      expect(await remote(h.b), isEmpty);
      final runs = await h.db.select(h.db.backupRuns).get();
      expect(runs.where((r) => !r.ok).single.accountId, accB);
    });

    test('backup files are not indexed as user files', () async {
      await svc.backupNow();
      await h.sync.syncAccount(accA);
      expect(await h.files.list(), isEmpty);
    });

    test('a newer snapshot from another device is a conflict', () async {
      await svc.backupNow(); // device 1, counter 1
      // Device 2 sees the same clouds and writes counter 2.
      final h2 = Harness(providerA: h.a, providerB: h.b);
      await h2.connect(h2.a, 'a');
      await BackupKeyStore(h2.secrets)
          .store((await BackupKeyStore(h.secrets).load())!);
      await SettingsStore(h2.db).setInt(SettingKeys.backupCounter, 1);
      await build(h2).backupNow(force: true);
      // Device 1 still thinks counter is 1.
      await expectLater(svc.backupNow(), throwsA(isA<BackupConflict>()));
      // Nothing was written by the refused run.
      expect((await remote(h.a)).length, 2);
      // Overwriting is explicit and continues the sequence.
      await svc.backupNow(force: true);
      final counters = (await remote(
        h.a,
      )).map((f) => BackupFileName.parse(f.name)!.counter).toList()..sort();
      expect(counters, [1, 2, 3]);
      await h2.close();
    });

    test('own newer snapshots are not a conflict', () async {
      await svc.backupNow();
      await svc.backupNow();
      await svc.backupNow();
      expect((await remote(h.a)).length, 3);
    });

    test('isDue / runIfDue follow the interval', () async {
      expect(await svc.isDue(), isTrue);
      expect(await svc.runIfDue(), isNotNull);
      expect(await svc.isDue(), isFalse);
      expect(await svc.runIfDue(), isNull);
      h.now = h.now.add(const Duration(hours: 7));
      expect(await svc.isDue(), isTrue);
      await SettingsStore(h.db).setInt(SettingKeys.backupIntervalHours, 24);
      expect(await svc.runIfDue(), isNull);
      h.now = h.now.add(const Duration(hours: 18));
      expect(await svc.runIfDue(), isNotNull);
    });

    test('no active accounts means nothing to do', () async {
      await h.accounts.remove(accA);
      await h.accounts.remove(accB);
      expect(await svc.backupNow(), isEmpty);
    });
  });
}
