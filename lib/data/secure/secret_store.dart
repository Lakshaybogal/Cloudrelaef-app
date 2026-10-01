import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where secrets live (refresh tokens, backup key). Never SQLite, never
/// backups.
abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);

  static String refreshTokenKey(int accountId) => 'refresh_token.$accountId';
  static const backupKey = 'backup_master_key';
}

/// OS keystore (Keychain, Keystore, DPAPI, libsecret).
class KeystoreSecretStore implements SecretStore {
  KeystoreSecretStore([FlutterSecureStorage? storage])
    : _s =
          storage ??
          // Unsigned macOS builds have no keychain access group, so use the
          // regular keychain instead of the data-protection one.
          const FlutterSecureStorage(
            mOptions: MacOsOptions(usesDataProtectionKeychain: false),
          );
  final FlutterSecureStorage _s;

  @override
  Future<String?> read(String key) => _s.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _s.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _s.delete(key: key);
}

/// For tests.
class InMemorySecretStore implements SecretStore {
  final Map<String, String> _m = {};

  @override
  Future<String?> read(String key) async => _m[key];
  @override
  Future<void> write(String key, String value) async => _m[key] = value;
  @override
  Future<void> delete(String key) async => _m.remove(key);
}
