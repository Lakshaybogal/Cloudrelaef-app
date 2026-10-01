import 'package:drift/drift.dart';

import '../data/db/database.dart';
import '../providers/registry.dart';
import '../providers/storage_provider.dart';
import 'accounts.dart';

class SyncResult {
  const SyncResult({required this.seen, required this.removed});
  final int seen;
  final int removed;
}

/// Brings the local index in line with what a cloud really holds, and keeps
/// quota numbers fresh.
class SyncService {
  SyncService(
    this._db,
    this._accounts,
    this._registry, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final AccountService _accounts;
  final ProviderRegistry _registry;
  final DateTime Function() _now;

  static const _snapshotEvery = Duration(hours: 3);

  Future<LinkedAccount> _account(int id) => (_db.select(
    _db.linkedAccounts,
  )..where((t) => t.id.equals(id))).getSingle();

  /// Reads the quota from the provider and stores it, plus a history row for
  /// the forecast (at most one per 3 hours).
  Future<void> refreshQuota(int accountId) async {
    final account = await _account(accountId);
    final provider = _registry.get(account.provider);
    final token = await _accounts.accessToken(accountId);
    Quota quota;
    try {
      quota = await provider.getQuota(token);
    } on ProviderError catch (e) {
      if (e is ReauthRequired) rethrow;
      // Some providers refuse quota with narrow scopes: estimate from the
      // files we manage, keep the last known total.
      final used = await _indexedBytes(accountId);
      quota = Quota(total: account.quotaTotal, used: used);
    }
    final now = _now();
    await (_db.update(
      _db.linkedAccounts,
    )..where((t) => t.id.equals(accountId))).write(
      LinkedAccountsCompanion(
        quotaTotal: Value(quota.total),
        quotaUsed: Value(quota.used),
        quotaSyncedAt: Value(now),
      ),
    );
    final last =
        await (_db.select(_db.quotaSnapshots)
              ..where((t) => t.accountId.equals(accountId))
              ..orderBy([(t) => OrderingTerm.desc(t.takenAt)])
              ..limit(1))
            .getSingleOrNull();
    if (last == null || now.difference(last.takenAt) >= _snapshotEvery) {
      await _db
          .into(_db.quotaSnapshots)
          .insert(
            QuotaSnapshotsCompanion.insert(
              accountId: accountId,
              takenAt: now,
              used: quota.used,
              total: Value(quota.total),
            ),
          );
    }
  }

  Future<int> _indexedBytes(int accountId) async {
    final sum = _db.files.size.sum();
    final row =
        await (_db.selectOnly(_db.files)
              ..addColumns([sum])
              ..where(_db.files.accountId.equals(accountId)))
            .getSingle();
    return row.read(sum) ?? 0;
  }

  /// Full scan of one account. Files that vanished at the provider are
  /// removed from the index; folder placement and trash state of surviving
  /// files are kept.
  Future<SyncResult> syncAccount(int accountId) async {
    final account = await _account(accountId);
    final provider = _registry.get(account.provider);
    final token = await _accounts.accessToken(accountId);
    final seenIds = <String>{};
    var seen = 0;
    String? cursor;
    do {
      final page = await provider.listFiles(token, cursor: cursor);
      await _db.transaction(() async {
        for (final f in page.files) {
          seenIds.add(f.remoteId);
          seen++;
          await _db
              .into(_db.files)
              .insert(
                FilesCompanion.insert(
                  accountId: accountId,
                  remoteId: f.remoteId,
                  name: f.name,
                  path: Value(f.path),
                  size: Value(f.size),
                  mime: Value(f.mime),
                  hash: Value(f.hash),
                  modifiedAt: Value(f.modifiedAt),
                  indexedAt: _now(),
                ),
                onConflict: DoUpdate(
                  (_) => FilesCompanion(
                    name: Value(f.name),
                    path: Value(f.path),
                    size: Value(f.size),
                    mime: Value(f.mime),
                    hash: Value(f.hash),
                    modifiedAt: Value(f.modifiedAt),
                    indexedAt: Value(_now()),
                  ),
                  target: [_db.files.accountId, _db.files.remoteId],
                ),
              );
        }
      });
      cursor = page.nextCursor;
    } while (cursor != null);

    final existing = await (_db.select(
      _db.files,
    )..where((t) => t.accountId.equals(accountId))).get();
    final gone = [
      for (final f in existing)
        if (!seenIds.contains(f.remoteId)) f.id,
    ];
    if (gone.isNotEmpty) {
      await (_db.delete(_db.files)..where((t) => t.id.isIn(gone))).go();
    }
    await (_db.update(_db.linkedAccounts)..where((t) => t.id.equals(accountId)))
        .write(LinkedAccountsCompanion(lastSyncedAt: Value(_now())));
    await refreshQuota(accountId);
    return SyncResult(seen: seen, removed: gone.length);
  }

  /// Syncs every active account; one failing account does not stop the rest.
  Future<Map<int, Object?>> syncAll() async {
    final out = <int, Object?>{};
    for (final a in await _accounts.list()) {
      if (a.status != AccountStatus.active) continue;
      try {
        out[a.id] = await syncAccount(a.id);
      } catch (e) {
        out[a.id] = e;
      }
    }
    return out;
  }
}
