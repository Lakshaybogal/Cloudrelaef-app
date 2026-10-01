import 'package:drift/drift.dart';

import '../data/db/database.dart';
import '../providers/registry.dart';
import '../providers/storage_provider.dart';
import 'accounts.dart';
import 'placement.dart';
import 'sync.dart';

class FileException implements Exception {
  FileException(this.message);
  final String message;
  @override
  String toString() => message;
}

class TransferResult {
  const TransferResult({required this.fileId, required this.sourceDeleted});
  final int fileId;

  /// False when the copy succeeded but deleting the original failed.
  final bool sourceDeleted;
}

/// Upload, download, rename, trash and transfer of files across the pool.
class FileService {
  FileService(
    this._db,
    this._accounts,
    this._registry,
    this._sync,
    this._placement, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final AccountService _accounts;
  final ProviderRegistry _registry;
  final SyncService _sync;
  final PlacementEngine _placement;
  final DateTime Function() _now;

  static const _quotaMaxAge = Duration(minutes: 5);

  Future<FileEntry> get(int id) async {
    final f = await (_db.select(
      _db.files,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (f == null) throw FileException('File not found');
    return f;
  }

  Future<LinkedAccount> _account(int id) => (_db.select(
    _db.linkedAccounts,
  )..where((t) => t.id.equals(id))).getSingle();

  /// Search and list the index. [folderId] null = everywhere unless
  /// [topLevelOnly]; trashed files are excluded unless [trashed].
  Future<List<FileEntry>> list({
    String? query,
    int? folderId,
    bool topLevelOnly = false,
    int? accountId,
    bool trashed = false,
    int limit = 500,
    int offset = 0,
  }) {
    final q = _db.select(_db.files)
      ..where((t) {
        Expression<bool> w = trashed
            ? t.trashedAt.isNotNull()
            : t.trashedAt.isNull();
        if (folderId != null) w = w & t.folderId.equals(folderId);
        if (topLevelOnly) w = w & t.folderId.isNull();
        if (accountId != null) w = w & t.accountId.equals(accountId);
        if (query != null && query.trim().isNotEmpty) {
          final escaped = query
              .trim()
              .replaceAll(r'\', r'\\')
              .replaceAll('%', r'\%')
              .replaceAll('_', r'\_');
          w = w & t.name.like('%$escaped%', escapeChar: r'\');
        }
        return w;
      })
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)])
      ..limit(limit, offset: offset);
    return q.get();
  }

  Future<List<Candidate>> _candidates() async => [
    for (final a in await _accounts.list())
      Candidate(
        accountId: a.id,
        provider: a.provider,
        active: a.status == AccountStatus.active,
        total: a.quotaTotal,
        used: a.quotaUsed,
      ),
  ];

  /// Uploads to the best-fit account. [size] must be known up front.
  Future<FileEntry> upload({
    required String name,
    required int size,
    required String mime,
    required Stream<List<int>> data,
    int? folderId,
  }) async {
    // Stale quota would mis-place files: refresh the ones older than 5 minutes.
    for (final a in await _accounts.list()) {
      if (a.status != AccountStatus.active) continue;
      final age = a.quotaSyncedAt == null
          ? null
          : _now().difference(a.quotaSyncedAt!);
      if (age == null || age > _quotaMaxAge) {
        try {
          await _sync.refreshQuota(a.id);
        } on ReauthRequired {
          // The account is now flagged and skipped by placement.
        }
      }
    }
    final target = _placement.place(await _candidates(), size);
    final account = await _account(target.accountId);
    final token = await _accounts.accessToken(account.id);
    final remote = await _registry
        .get(account.provider)
        .upload(token, name: name, size: size, mime: mime, data: data);
    final id = await _insert(account.id, remote, folderId);
    await _db.customUpdate(
      'UPDATE linked_accounts SET quota_used = quota_used + ? WHERE id = ?',
      variables: [Variable.withInt(size), Variable.withInt(account.id)],
      updates: {_db.linkedAccounts},
    );
    return get(id);
  }

  Future<int> _insert(int accountId, RemoteFile r, int? folderId) => _db
      .into(_db.files)
      .insert(
        FilesCompanion.insert(
          accountId: accountId,
          remoteId: r.remoteId,
          name: r.name,
          path: Value(r.path),
          size: Value(r.size),
          mime: Value(r.mime),
          hash: Value(r.hash),
          modifiedAt: Value(r.modifiedAt),
          indexedAt: _now(),
          folderId: Value(folderId),
        ),
      );

  Future<Stream<List<int>>> download(int id) async {
    final f = await get(id);
    final account = await _account(f.accountId);
    final token = await _accounts.accessToken(account.id);
    return _registry.get(account.provider).download(token, f.remoteId);
  }

  Future<void> rename(int id, String name) async {
    final f = await get(id);
    final account = await _account(f.accountId);
    final token = await _accounts.accessToken(account.id);
    final r = await _registry
        .get(account.provider)
        .rename(token, f.remoteId, name);
    await (_db.update(_db.files)..where((t) => t.id.equals(id))).write(
      FilesCompanion(name: Value(r.name), path: Value(r.path)),
    );
  }

  /// Local only: folders are virtual.
  Future<void> moveToFolder(int id, int? folderId) =>
      (_db.update(_db.files)..where((t) => t.id.equals(id))).write(
        FilesCompanion(folderId: Value(folderId)),
      );

  /// "Delete" moves to the trash; the cloud copy stays until [purge].
  Future<void> trash(int id) =>
      (_db.update(_db.files)..where((t) => t.id.equals(id))).write(
        FilesCompanion(trashedAt: Value(_now())),
      );

  Future<void> restore(int id) async {
    final f = await get(id);
    final folderStillExists =
        f.folderId != null &&
        await (_db.select(
              _db.folders,
            )..where((t) => t.id.equals(f.folderId!))).getSingleOrNull() !=
            null;
    await (_db.update(_db.files)..where((t) => t.id.equals(id))).write(
      FilesCompanion(
        trashedAt: const Value(null),
        folderId: folderStillExists ? Value(f.folderId) : const Value(null),
      ),
    );
  }

  /// Deletes at the cloud first; if the cloud refuses the entry is kept.
  Future<void> purge(int id) async {
    final f = await get(id);
    if (f.trashedAt == null) {
      throw FileException('Only trashed files can be deleted for good');
    }
    final account = await _account(f.accountId);
    final token = await _accounts.accessToken(account.id);
    await _registry.get(account.provider).delete(token, f.remoteId);
    await (_db.delete(_db.files)..where((t) => t.id.equals(id))).go();
    await _sync.refreshQuota(account.id);
  }

  /// Moves (or copies with [keepOriginal]) a file to another account by
  /// piping the download straight into the upload.
  Future<TransferResult> transfer(
    int id,
    int targetAccountId, {
    bool keepOriginal = false,
  }) async {
    final f = await get(id);
    if (f.accountId == targetAccountId) {
      throw FileException('The file is already on that account');
    }
    final target = await _account(targetAccountId);
    if (target.status != AccountStatus.active) {
      throw FileException('Target account needs to be reconnected');
    }
    final candidate = Candidate(
      accountId: target.id,
      provider: target.provider,
      active: true,
      total: target.quotaTotal,
      used: target.quotaUsed,
    );
    // Reuses the engine's rules (free space + margin) for the single target.
    _placement.place([candidate], f.size);

    final source = await _account(f.accountId);
    final sourceToken = await _accounts.accessToken(source.id);
    final targetToken = await _accounts.accessToken(target.id);
    final remote = await _registry
        .get(target.provider)
        .upload(
          targetToken,
          name: f.name,
          size: f.size,
          mime: f.mime,
          data: _registry
              .get(source.provider)
              .download(sourceToken, f.remoteId),
        );

    int resultId;
    var sourceDeleted = false;
    if (keepOriginal) {
      resultId = await _insert(target.id, remote, f.folderId);
      sourceDeleted = true; // nothing to delete
    } else {
      // Repoint the same row so id, folder and trash state are kept.
      await (_db.update(_db.files)..where((t) => t.id.equals(id))).write(
        FilesCompanion(
          accountId: Value(target.id),
          remoteId: Value(remote.remoteId),
          path: Value(remote.path),
          hash: Value(remote.hash),
        ),
      );
      resultId = id;
      try {
        await _registry.get(source.provider).delete(sourceToken, f.remoteId);
        sourceDeleted = true;
      } on ProviderError {
        sourceDeleted = false;
      }
    }
    await _sync.refreshQuota(target.id);
    if (!keepOriginal && sourceDeleted) await _sync.refreshQuota(source.id);
    return TransferResult(fileId: resultId, sourceDeleted: sourceDeleted);
  }
}
