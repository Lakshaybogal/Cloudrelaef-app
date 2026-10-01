import 'dart:convert';

import '../data/secure/secret_store.dart';
import '../providers/storage_provider.dart';

/// Stores the user's own OAuth client ids (bring-your-own-keys) per provider.
class OAuthConfigStore {
  OAuthConfigStore(this._secrets);
  final SecretStore _secrets;

  static String _key(String provider) => 'oauth_client.$provider';

  Future<OAuthClientConfig?> read(String provider) async {
    final raw = await _secrets.read(_key(provider));
    if (raw == null) return null;
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return OAuthClientConfig(
      clientId: m['client_id'] as String,
      clientSecret: m['client_secret'] as String?,
    );
  }

  Future<void> write(String provider, OAuthClientConfig c) {
    if (c.clientId.trim().isEmpty) {
      throw ArgumentError('Client ID must not be empty');
    }
    return _secrets.write(
      _key(provider),
      jsonEncode({
        'client_id': c.clientId.trim(),
        if (c.clientSecret != null && c.clientSecret!.trim().isNotEmpty)
          'client_secret': c.clientSecret!.trim(),
      }),
    );
  }

  Future<void> delete(String provider) => _secrets.delete(_key(provider));
}
