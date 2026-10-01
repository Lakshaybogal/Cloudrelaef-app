import 'dart:io';

import 'package:drift/native.dart';

import 'database.dart';

/// Owns the on-disk database so it can be replaced wholesale by a restore.
/// After [replaceWith] every service built on the old [db] must be rebuilt.
class DatabaseHost {
  DatabaseHost._(this.file, this.db);
  final File file;
  AppDatabase db;

  static Future<DatabaseHost> open(File file) async {
    await file.parent.create(recursive: true);
    return DatabaseHost._(file, AppDatabase(NativeDatabase(file)));
  }

  /// Closes the current database, puts [replacement] in its place and
  /// reopens. [replacement] is consumed (moved/deleted).
  Future<AppDatabase> replaceWith(File replacement) async {
    await db.close();
    for (final suffix in const ['-wal', '-shm', '-journal']) {
      final f = File('${file.path}$suffix');
      if (await f.exists()) await f.delete();
    }
    await replacement.copy(file.path);
    await replacement.delete();
    db = AppDatabase(NativeDatabase(file));
    return db;
  }

  Future<void> close() => db.close();
}
