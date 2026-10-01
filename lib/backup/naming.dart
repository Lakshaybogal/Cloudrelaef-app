/// Backup files live in each cloud's app folder next to normal files, so
/// their names are recognisable and the index skips them.
const backupFilePrefix = 'cloudrelaef-backup-';
const backupFileSuffix = '.crb';

bool isBackupFileName(String name) =>
    name.startsWith(backupFilePrefix) && name.endsWith(backupFileSuffix);

class BackupFileName {
  const BackupFileName({required this.counter, required this.deviceId});
  final int counter;
  final String deviceId;

  String get fileName =>
      '$backupFilePrefix${counter.toString().padLeft(10, '0')}-$deviceId$backupFileSuffix';

  /// Null when [name] is not a valid backup file name.
  static BackupFileName? parse(String name) {
    final m = RegExp(
      '^${RegExp.escape(backupFilePrefix)}(\\d{10})-([0-9a-f]{8})${RegExp.escape(backupFileSuffix)}\$',
    ).firstMatch(name);
    if (m == null) return null;
    return BackupFileName(counter: int.parse(m[1]!), deviceId: m[2]!);
  }
}
