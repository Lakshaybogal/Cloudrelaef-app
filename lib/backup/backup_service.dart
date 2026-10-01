import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';

import '../data/db/database.dart';
import '../providers/registry.dart';
import '../providers/storage_provider.dart';
import '../services/accounts.dart';
import '../services/settings.dart';
import 'key_store.dart';
import 'naming.dart';
import 'snapshot.dart';

class BackupNotSetUp implements Exception {
  @override
  String toString() => 'Backups are not set up yet';
}

/// Another device wrote a newer snapshot than this device knows about.
class BackupConflict implements Exception {
  BackupConflict({
    required this.remoteCounter,
    required this.remoteDeviceId,
    required this.cloud,
  });
  final int remoteCounter;
  final String remoteDeviceId;
  final String cloud;
  @override
  String toString() =>
      'A newer backup from another device exists on $cloud '
      '(#$remoteCounter). Restore it or overwrite it.';
}

class CloudBackupResult {
  const CloudBackupResult({
    required this.accountId,
    required this.displayName,
    required this.ok,
    this.error,
  });
  final int accountId;
  final String displayName;
  final bool ok;
  final String? error;
}

class RemoteSnapshot {
  const RemoteSnapshot({
    required this.accountId,
    required this.file,
    required this.name,
  });
  final int accountId;
  final RemoteFile file;
  final BackupFileName name;
}

/// Writes an encrypted snapshot of the database (never the files) to every
/// connected cloud.
class BackupService {
  BackupService({
    required this.db,
    required this.accounts,
    required this.registry,
    required this.keys,
    required this.settings,
    required this.tempDir,
    SnapshotCodec? codec,
    DateTime Function()? now,
    Random? rng,
  }) : codec = codec ?? SnapshotCodec(),
       _now = now ?? DateTime.now,
       _rng = rng ?? Random.secure();

  final AppDatabase db;
  final AccountService accounts;
  final ProviderRegistry registry;
  final BackupKeyStore keys;
  final SettingsStore settings;
  final Directory tempDir;
  final SnapshotCodec codec;
  final DateTime Function() _now;
  final Random _rng;

  static const defaultKeep = 10;
  static const defaultIntervalHours = 6;
  static const lastBackupKey = 'last_backup_at';

  String _hex(int bytes) => [
    for (var i = 0; i < bytes; i++)
      _rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();

  Future<String> deviceId() async {
    var id = await settings.get(SettingKeys.deviceId);
    if (id == null) {
      id = _hex(4);
      await settings.set(SettingKeys.deviceId, id);
    }
    return id;
  }

  /// Backup files on one cloud, newest first.
  Future<List<RemoteSnapshot>> listRemote(LinkedAccount account) async {
    final provider = registry.get(account.provider);
    final token = await accounts.accessToken(account.id);
    final out = <RemoteSnapshot>[];
    String? cursor;
    do {
      final page = await provider.listFiles(token, cursor: cursor);
      for (final f in page.files) {
        final parsed = BackupFileName.parse(f.name);
        if (parsed != null) {
          out.add(RemoteSnapshot(accountId: account.id, file: f, name: parsed));
        }
      }
      cursor = page.nextCursor;
    } while (cursor != null);
    out.sort((a, b) => b.name.counter.compareTo(a.name.counter));
    return out;
  }

  /// Backs up to every active cloud. Throws [BackupConflict] before writing
  /// anything when another device is ahead, unless [force].
  Future<List<CloudBackupResult>> backupNow({bool force = false}) async {
    final key = await keys.load();
    if (key == null) throw BackupNotSetUp();
    final active = [
      for (final a in await accounts.list())
        if (a.status == AccountStatus.active) a,
    ];
    if (active.isEmpty) return const [];

    final me = await deviceId();
    final localCounter = await settings.getInt(SettingKeys.backupCounter) ?? 0;

    // 1. What is already out there? (Failures here only skip that cloud.)
    final remote = <int, List<RemoteSnapshot>>{};
    final listErrors = <int, String>{};
    for (final a in active) {
      try {
        remote[a.id] = await listRemote(a);
      } on ReauthRequired {
        listErrors[a.id] = 'Reconnect this account';
      } on ProviderError catch (e) {
        listErrors[a.id] = e.message;
      }
    }
    var highest = localCounter;
    for (final entry in remote.entries) {
      final account = active.firstWhere((a) => a.id == entry.key);
      for (final s in entry.value) {
        if (s.name.counter > highest) highest = s.name.counter;
        if (!force && s.name.counter > localCounter && s.name.deviceId != me) {
          throw BackupConflict(
            remoteCounter: s.name.counter,
            remoteDeviceId: s.name.deviceId,
            cloud: account.displayName,
          );
        }
      }
    }

    // 2. One snapshot, uploaded everywhere.
    final counter = highest + 1;
    await settings.setInt(SettingKeys.backupCounter, counter);
    final snapshotId = _hex(8);
    final blob = await codec.create(
      db: db,
      tempDir: tempDir,
      key: key,
      snapshotId: snapshotId,
      counter: counter,
      deviceId: me,
      now: _now(),
    );
    final name = BackupFileName(counter: counter, deviceId: me).fileName;
    final keep = await settings.getInt(SettingKeys.backupKeep) ?? defaultKeep;

    final results = <CloudBackupResult>[];
    for (final a in active) {
      CloudBackupResult result;
      if (listErrors.containsKey(a.id)) {
        result = CloudBackupResult(
          accountId: a.id,
          displayName: a.displayName,
          ok: false,
          error: listErrors[a.id],
        );
      } else {
        try {
          final token = await accounts.accessToken(a.id);
          await registry
              .get(a.provider)
              .upload(
                token,
                name: name,
                size: blob.length,
                mime: 'application/octet-stream',
                data: Stream.value(blob),
              );
          await _prune(a, remote[a.id] ?? const [], counter, keep);
          result = CloudBackupResult(
            accountId: a.id,
            displayName: a.displayName,
            ok: true,
          );
        } on ProviderError catch (e) {
          result = CloudBackupResult(
            accountId: a.id,
            displayName: a.displayName,
            ok: false,
            error: e is ReauthRequired ? 'Reconnect this account' : e.message,
          );
        }
      }
      results.add(result);
      await db
          .into(db.backupRuns)
          .insert(
            BackupRunsCompanion.insert(
              accountId: a.id,
              at: _now(),
              snapshotId: snapshotId,
              ok: result.ok,
              error: Value(result.error),
            ),
          );
    }
    if (results.any((r) => r.ok)) {
      await settings.set(lastBackupKey, _now().toUtc().toIso8601String());
    }
    return results;
  }

  /// Deletes snapshots beyond the newest [keep]; never the one just written.
  Future<void> _prune(
    LinkedAccount account,
    List<RemoteSnapshot> existing,
    int newCounter,
    int keep,
  ) async {
    final all = [...existing]
      ..sort((a, b) => b.name.counter.compareTo(a.name.counter));
    // `keep` includes the new snapshot.
    final doomed = all
        .where((s) => s.name.counter != newCounter)
        .skip(keep - 1);
    final token = await accounts.accessToken(account.id);
    for (final s in doomed) {
      try {
        await registry.get(account.provider).delete(token, s.file.remoteId);
      } on ProviderError {
        // Pruning is best effort; the next run tries again.
      }
    }
  }

  Future<DateTime?> lastSuccess() async {
    final v = await settings.get(lastBackupKey);
    return v == null ? null : DateTime.tryParse(v);
  }

  Future<bool> isDue() async {
    final last = await lastSuccess();
    if (last == null) return true;
    final hours =
        await settings.getInt(SettingKeys.backupIntervalHours) ??
        defaultIntervalHours;
    return _now().difference(last) >= Duration(hours: hours);
  }

  /// Backs up only if the interval has elapsed. Call on app open and from a
  /// timer / the OS background scheduler. Returns null when not due.
  Future<List<CloudBackupResult>?> runIfDue() async {
    if (await keys.load() == null) return null;
    if (!await isDue()) return null;
    return backupNow();
  }

  Future<Uint8List> download(RemoteSnapshot s) async {
    final account = await (db.select(
      db.linkedAccounts,
    )..where((t) => t.id.equals(s.accountId))).getSingle();
    final token = await accounts.accessToken(account.id);
    final chunks = await registry
        .get(account.provider)
        .download(token, s.file.remoteId)
        .toList();
    return Uint8List.fromList([for (final c in chunks) ...c]);
  }
}
