import 'dart:convert';
import 'dart:typed_data';

import '../data/secure/secret_store.dart';
import 'crypto.dart';

/// Keeps the backup master key in the OS keystore.
class BackupKeyStore {
  BackupKeyStore(this._secrets);
  final SecretStore _secrets;

  Future<Uint8List?> load() async {
    final raw = await _secrets.read(SecretStore.backupKey);
    return raw == null ? null : Uint8List.fromList(base64Decode(raw));
  }

  Future<void> store(Uint8List key) =>
      _secrets.write(SecretStore.backupKey, base64Encode(key));

  /// Creates the key on first use. Returns the key and whether it is new, so
  /// the UI can force the user to save the recovery code.
  Future<({Uint8List key, bool created})> ensure() async {
    final existing = await load();
    if (existing != null) return (key: existing, created: false);
    final key = RecoveryKey.generate();
    await store(key);
    return (key: key, created: true);
  }
}
