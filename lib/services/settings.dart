import '../data/db/database.dart';

/// Key/value settings stored in the database (so they travel in backups).
class SettingsStore {
  SettingsStore(this._db);
  final AppDatabase _db;

  Future<String?> get(String key) async => (await (_db.select(
    _db.appSettings,
  )..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> set(String key, String value) => _db
      .into(_db.appSettings)
      .insertOnConflictUpdate(
        AppSettingsCompanion.insert(key: key, value: value),
      );

  Future<int?> getInt(String key) async {
    final v = await get(key);
    return v == null ? null : int.tryParse(v);
  }

  Future<void> setInt(String key, int value) => set(key, '$value');
}

class SettingKeys {
  static const deviceId = 'device_id';
  static const backupCounter = 'backup_counter';
  static const backupIntervalHours = 'backup_interval_hours';
  static const backupKeep = 'backup_keep';
  static const placementStrategy = 'placement_strategy';
}
