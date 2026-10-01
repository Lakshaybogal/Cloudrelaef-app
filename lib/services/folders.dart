import 'package:drift/drift.dart';

import '../data/db/database.dart';

class FolderException implements Exception {
  FolderException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Virtual folders: they exist only in the local database.
class FolderService {
  FolderService(this._db);
  final AppDatabase _db;

  Future<List<Folder>> list() => _db.select(_db.folders).get();

  Future<int> create(String name, {int? parentId}) async {
    final clean = _clean(name);
    await _requireFreeName(clean, parentId);
    return _db
        .into(_db.folders)
        .insert(
          FoldersCompanion.insert(name: clean, parentId: Value(parentId)),
        );
  }

  Future<void> rename(int id, String name) async {
    final clean = _clean(name);
    final f = await _get(id);
    await _requireFreeName(clean, f.parentId, except: id);
    await (_db.update(_db.folders)..where((t) => t.id.equals(id))).write(
      FoldersCompanion(name: Value(clean)),
    );
  }

  /// Moves a folder; [parentId] null = top level. Refuses cycles.
  Future<void> move(int id, int? parentId) async {
    final f = await _get(id);
    var cursor = parentId;
    while (cursor != null) {
      if (cursor == id) {
        throw FolderException('A folder cannot move into itself');
      }
      cursor = (await _get(cursor)).parentId;
    }
    await _requireFreeName(f.name, parentId, except: id);
    await (_db.update(_db.folders)..where((t) => t.id.equals(id))).write(
      FoldersCompanion(parentId: Value(parentId)),
    );
  }

  /// Only an empty folder can be deleted.
  Future<void> delete(int id) async {
    final subfolders =
        await (_db.select(_db.folders)
              ..where((t) => t.parentId.equals(id))
              ..limit(1))
            .get();
    final files =
        await (_db.select(_db.files)
              ..where((t) => t.folderId.equals(id))
              ..limit(1))
            .get();
    if (subfolders.isNotEmpty || files.isNotEmpty) {
      throw FolderException('Folder is not empty');
    }
    await (_db.delete(_db.folders)..where((t) => t.id.equals(id))).go();
  }

  Future<Folder> _get(int id) async {
    final f = await (_db.select(
      _db.folders,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (f == null) throw FolderException('Folder not found');
    return f;
  }

  String _clean(String name) {
    final n = name.trim();
    if (n.isEmpty) throw FolderException('Folder name must not be empty');
    if (n.contains('/')) {
      throw FolderException('Folder name must not contain /');
    }
    return n;
  }

  Future<void> _requireFreeName(
    String name,
    int? parentId, {
    int? except,
  }) async {
    final siblings =
        await (_db.select(_db.folders)..where(
              (t) => parentId == null
                  ? t.parentId.isNull()
                  : t.parentId.equals(parentId),
            ))
            .get();
    final taken = siblings.any(
      (s) => s.id != except && s.name.toLowerCase() == name.toLowerCase(),
    );
    if (taken) {
      throw FolderException('A folder named "$name" already exists here');
    }
  }
}
