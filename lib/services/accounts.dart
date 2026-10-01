import 'package:drift/drift.dart';

import '../data/db/database.dart';
import '../data/secure/secret_store.dart';
import '../providers/registry.dart';
import '../providers/storage_provider.dart';

class AccountStatus {
  static const active = 'active';
  static const needsReauth = 'needs_reauth';
}

/// Connected accounts: rows in the database, refresh tokens in the secret
/// store, short-lived access tokens in memory.
class AccountService {
  AccountService(
    this._db,
    this._secrets,
    this._registry, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final SecretStore _secrets;
  final ProviderRegistry _registry;
  final DateTime Function() _now;

  final Map<int, AccessToken> _cache = {};
  final Map<int, Future<AccessToken>> _inFlight = {};

  Future<List<LinkedAccount>> list() => _db.select(_db.linkedAccounts).get();

  /// Saves a freshly connected account. Reconnecting the same cloud account
  /// keeps its row (and therefore its files) and clears `needs_reauth`.
  Future<int> add(String provider, TokenSet tokens) async {
    final existing =
        await (_db.select(_db.linkedAccounts)..where(
              (t) =>
                  t.provider.equals(provider) &
                  t.providerAccountId.equals(tokens.accountId),
            ))
            .getSingleOrNull();
    final int id;
    if (existing != null) {
      id = existing.id;
      await (_db.update(
        _db.linkedAccounts,
      )..where((t) => t.id.equals(id))).write(
        LinkedAccountsCompanion(
          displayName: Value(tokens.displayName),
          status: const Value(AccountStatus.active),
        ),
      );
    } else {
      id = await _db
          .into(_db.linkedAccounts)
          .insert(
            LinkedAccountsCompanion.insert(
              provider: provider,
              providerAccountId: tokens.accountId,
              displayName: tokens.displayName,
            ),
          );
    }
    await _secrets.write(SecretStore.refreshTokenKey(id), tokens.refreshToken);
    _cache[id] = tokens.access;
    return id;
  }

  /// Unlinks the account. Files stay at the provider.
  Future<void> remove(int id) async {
    await (_db.delete(_db.linkedAccounts)..where((t) => t.id.equals(id))).go();
    await _secrets.delete(SecretStore.refreshTokenKey(id));
    _cache.remove(id);
  }

  /// A valid access token, refreshing when it expires within a minute.
  /// Concurrent callers share one refresh (matters for rotating refresh
  /// tokens, where two parallel refreshes would invalidate each other).
  Future<AccessToken> accessToken(int id) {
    final cached = _cache[id];
    if (cached != null &&
        cached.expiresAt.isAfter(_now().add(const Duration(seconds: 60)))) {
      return Future.value(cached);
    }
    return _inFlight[id] ??= _refresh(id).whenComplete(() {
      // Block body on purpose: returning the removed future would make
      // whenComplete wait on itself.
      _inFlight.remove(id);
    });
  }

  Future<AccessToken> _refresh(int id) async {
    final account = await (_db.select(
      _db.linkedAccounts,
    )..where((t) => t.id.equals(id))).getSingle();
    final refresh = await _secrets.read(SecretStore.refreshTokenKey(id));
    if (refresh == null) {
      await _markReauth(id);
      throw ReauthRequired('No stored credentials; reconnect the account');
    }
    try {
      final token = await _registry.get(account.provider).refreshToken(refresh);
      if (token.newRefreshToken != null) {
        await _secrets.write(
          SecretStore.refreshTokenKey(id),
          token.newRefreshToken!,
        );
      }
      return _cache[id] = token;
    } on ReauthRequired {
      _cache.remove(id);
      await _markReauth(id);
      rethrow;
    }
  }

  Future<void> _markReauth(int id) =>
      (_db.update(_db.linkedAccounts)..where((t) => t.id.equals(id))).write(
        const LinkedAccountsCompanion(status: Value(AccountStatus.needsReauth)),
      );
}
