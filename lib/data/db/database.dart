import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// A connected cloud account. The refresh token is NOT here: it lives in the
/// [SecretStore]. Snapshots therefore never contain credentials.
class LinkedAccounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get provider => text()();
  TextColumn get providerAccountId => text()();
  TextColumn get displayName => text()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  IntColumn get quotaTotal => integer().nullable()();
  IntColumn get quotaUsed => integer().withDefault(const Constant(0))();
  DateTimeColumn get quotaSyncedAt => dateTime().nullable()();
  TextColumn get syncCursor => text().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {provider, providerAccountId},
  ];
}

/// Virtual folders: they exist only in this database.
class Folders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get parentId => integer().nullable().references(
    Folders,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get name => text()();
}

@DataClassName('FileEntry')
class Files extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get accountId =>
      integer().references(LinkedAccounts, #id, onDelete: KeyAction.cascade)();
  IntColumn get folderId => integer().nullable().references(
    Folders,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get remoteId => text()();
  TextColumn get name => text()();
  TextColumn get path => text().withDefault(const Constant(''))();
  IntColumn get size => integer().withDefault(const Constant(0))();
  TextColumn get mime => text().withDefault(const Constant(''))();
  TextColumn get hash => text().nullable()();
  DateTimeColumn get modifiedAt => dateTime().nullable()();
  DateTimeColumn get indexedAt => dateTime()();
  DateTimeColumn get trashedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {accountId, remoteId},
  ];
}

class QuotaSnapshots extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get accountId =>
      integer().references(LinkedAccounts, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get takenAt => dateTime()();
  IntColumn get used => integer()();
  IntColumn get total => integer().nullable()();
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// One row per backup attempt per cloud.
class BackupRuns extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get accountId =>
      integer().references(LinkedAccounts, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get at => dateTime()();
  TextColumn get snapshotId => text()();
  BoolColumn get ok => boolean()();
  TextColumn get error => text().nullable()();
}

@DriftDatabase(
  tables: [
    LinkedAccounts,
    Folders,
    Files,
    QuotaSnapshots,
    AppSettings,
    BackupRuns,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// In-memory database for tests.
  AppDatabase.memory() : super(NativeDatabase.memory());

  /// The on-device database in the app documents directory.
  static Future<AppDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();
    return AppDatabase(
      NativeDatabase.createInBackground(
        File(p.join(dir.path, 'cloudrelaef.sqlite')),
      ),
    );
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
