import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';

import '../data/db/database.dart';
import '../data/db/database_host.dart';
import '../data/secure/secret_store.dart';
import '../providers/registry.dart';
import '../providers/storage_provider.dart';
import '../services/accounts.dart';
import '../services/settings.dart';
import 'backup_service.dart';
import 'crypto.dart';
import 'key_store.dart';
import 'snapshot.dart';

class RestoreOutcome {
  const RestoreOutcome({
    required this.snapshotCounter,
    required this.fromCloud,
    required this.accountsNeedingReauth,
  });
  final int snapshotCounter;
  final String fromCloud;
  final int accountsNeedingReauth;
}

class NoBackupFound implements Exception {
  @override
  String toString() => 'No CloudRelaef backup found on the connected accounts';
}

/// Restores the database from the newest valid snapshot on any connected
/// cloud, using the recovery key.
///
/// After this returns, [DatabaseHost.db] is a new instance: rebuild every
/// service that held the old one.
class RestoreService {
  RestoreService({
    required this.host,
    required this.secrets,
    required this.registry,
    required this.tempDir,
    SnapshotCodec? codec,
    Random? rng,
  }) : codec = codec ?? SnapshotCodec(),
       _rng = rng ?? Random.secure();

  final DatabaseHost host;
  final SecretStore secrets;
  final ProviderRegistry registry;
  final Directory tempDir;
  final SnapshotCodec codec;
  final Random _rng;

  /// [accounts] must be built on the current (pre-restore) database; these
  /// are the clouds the user has just connected on this device.
  Future<RestoreOutcome> restoreLatest({
    required AccountService accounts,
    required Uint8List key,
  }) async {
    final before = host.db;
    final connected = await before.select(before.linkedAccounts).get();
    final refreshTokens = <int, String>{};
    for (final a in connected) {
      final t = await secrets.read(SecretStore.refreshTokenKey(a.id));
      if (t != null) refreshTokens[a.id] = t;
    }

    final backup = BackupService(
      db: before,
      accounts: accounts,
      registry: registry,
      keys: BackupKeyStore(secrets),
      settings: SettingsStore(before),
      tempDir: tempDir,
    );

    final candidates = <RemoteSnapshot>[];
    for (final a in connected) {
      if (a.status != AccountStatus.active) continue;
      try {
        candidates.addAll(await backup.listRemote(a));
      } on ProviderError {
        // An unreachable cloud must not block restoring from another.
      }
    }
    if (candidates.isEmpty) throw NoBackupFound();
    candidates.sort((a, b) => b.name.counter.compareTo(a.name.counter));

    // Newest first; fall through to older/other clouds when one is damaged.
    BackupCryptoException? lastError;
    for (final c in candidates) {
      try {
        final blob = await backup.download(c);
        final opened = await codec.open(
          blob: blob,
          key: key,
          tempDir: tempDir,
          supportedSchema: before.schemaVersion,
        );
        final cloudName = connected
            .firstWhere((a) => a.id == c.accountId)
            .displayName;
        return await _apply(
          file: opened.file,
          counter: c.name.counter,
          cloudName: cloudName,
          connected: connected,
          refreshTokens: refreshTokens,
          key: key,
        );
      } on BackupCryptoException catch (e) {
        lastError = e;
      } on ProviderError {
        continue;
      }
    }
    throw lastError ?? NoBackupFound();
  }

  Future<RestoreOutcome> _apply({
    required File file,
    required int counter,
    required String cloudName,
    required List<LinkedAccount> connected,
    required Map<int, String> refreshTokens,
    required Uint8List key,
  }) async {
    final db = await host.replaceWith(file);
    // Every restored account lost its token with the old device...
    await db
        .update(db.linkedAccounts)
        .write(
          const LinkedAccountsCompanion(
            status: Value(AccountStatus.needsReauth),
          ),
        );
    // ...except the ones connected right now on this device.
    final restored = await db.select(db.linkedAccounts).get();
    var reconnected = 0;
    for (final old in connected) {
      final token = refreshTokens[old.id];
      await secrets.delete(SecretStore.refreshTokenKey(old.id));
      if (token == null) continue;
      final match = restored
          .where(
            (r) =>
                r.provider == old.provider &&
                r.providerAccountId == old.providerAccountId,
          )
          .firstOrNull;
      if (match == null) continue;
      await secrets.write(SecretStore.refreshTokenKey(match.id), token);
      await (db.update(
        db.linkedAccounts,
      )..where((t) => t.id.equals(match.id))).write(
        const LinkedAccountsCompanion(status: Value(AccountStatus.active)),
      );
      reconnected++;
    }
    // A restored device is a new writer: new id, and it continues counting.
    final settings = SettingsStore(db);
    await settings.set(
      SettingKeys.deviceId,
      [
        for (var i = 0; i < 4; i++)
          _rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ].join(),
    );
    await settings.setInt(SettingKeys.backupCounter, counter);
    await BackupKeyStore(secrets).store(key);

    final left = (await db.select(db.linkedAccounts).get())
        .where((a) => a.status != AccountStatus.active)
        .length;
    assert(reconnected >= 0);
    return RestoreOutcome(
      snapshotCounter: counter,
      fromCloud: cloudName,
      accountsNeedingReauth: left,
    );
  }
}
