import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../auth/oauth_config_store.dart';
import '../backup/backup_service.dart';
import '../backup/key_store.dart';
import '../backup/restore_service.dart';
import '../data/db/database_host.dart';
import '../data/secure/secret_store.dart';
import '../providers/registry.dart';
import '../services/accounts.dart';
import '../services/files.dart';
import '../services/folders.dart';
import '../services/placement.dart';
import '../services/settings.dart';
import '../services/sync.dart';
import 'provider_catalog.dart';

/// Everything the UI needs, wired on one database. After a restore the
/// database is replaced, so a new instance is built with [rebuild].
class AppServices {
  AppServices._({
    required this.host,
    required this.secrets,
    required this.catalog,
    required this.registry,
    required this.tempDir,
    required this.downloadsDir,
  }) {
    final db = host.db;
    settings = SettingsStore(db);
    accounts = AccountService(db, secrets, registry);
    sync = SyncService(db, accounts, registry);
    files = FileService(
      db,
      accounts,
      registry,
      sync,
      PlacementEngine(MostFreeSpace(), safetyMarginBytes: 50 * 1024 * 1024),
    );
    folders = FolderService(db);
    keys = BackupKeyStore(secrets);
    backup = BackupService(
      db: db,
      accounts: accounts,
      registry: registry,
      keys: keys,
      settings: settings,
      tempDir: tempDir,
    );
    restore = RestoreService(
      host: host,
      secrets: secrets,
      registry: registry,
      tempDir: tempDir,
    );
  }

  final DatabaseHost host;
  final SecretStore secrets;
  final ProviderCatalog catalog;
  final ProviderRegistry registry;
  final Directory tempDir;
  final Directory downloadsDir;

  late final SettingsStore settings;
  late final AccountService accounts;
  late final SyncService sync;
  late final FileService files;
  late final FolderService folders;
  late final BackupKeyStore keys;
  late final BackupService backup;
  late final RestoreService restore;

  /// Opens the real on-device database and keystore.
  static Future<AppServices> open() async {
    final docs = await getApplicationSupportDirectory();
    final host = await DatabaseHost.open(
      File(p.join(docs.path, 'cloudrelaef.sqlite')),
    );
    final secrets = KeystoreSecretStore();
    final catalog = ProviderCatalog(OAuthConfigStore(secrets));
    await catalog.load();
    final temp = Directory(
      p.join((await getTemporaryDirectory()).path, 'cloudrelaef'),
    );
    final downloads =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    return AppServices._(
      host: host,
      secrets: secrets,
      catalog: catalog,
      registry: catalog,
      tempDir: temp,
      downloadsDir: downloads,
    );
  }

  /// For tests and previews: bring your own host, secrets and registry.
  factory AppServices.custom({
    required DatabaseHost host,
    required SecretStore secrets,
    required ProviderCatalog catalog,
    required Directory tempDir,
    required Directory downloadsDir,
  }) => AppServices._(
    host: host,
    secrets: secrets,
    catalog: catalog,
    registry: catalog,
    tempDir: tempDir,
    downloadsDir: downloadsDir,
  );

  /// New service graph on the (possibly replaced) database.
  AppServices rebuild() => AppServices._(
    host: host,
    secrets: secrets,
    catalog: catalog,
    registry: registry,
    tempDir: tempDir,
    downloadsDir: downloadsDir,
  );
}
