import 'package:cloudrelaef/auth/oauth_config_store.dart';
import 'package:cloudrelaef/data/db/database.dart';
import 'package:cloudrelaef/data/secure/secret_store.dart';
import 'package:cloudrelaef/providers/registry.dart';
import 'package:cloudrelaef/providers/storage_provider.dart';
import 'package:cloudrelaef/services/accounts.dart';
import 'package:flutter_test/flutter_test.dart';

class _CountingProvider extends _Base {
  int refreshes = 0;
  bool rotate = false;
  bool revoked = false;
  @override
  Future<AccessToken> refreshToken(String refreshToken) async {
    refreshes++;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (revoked) throw ReauthRequired('revoked');
    return AccessToken(
      token: 'access-$refreshes',
      expiresAt: DateTime.utc(2030),
      newRefreshToken: rotate ? 'rotated-$refreshes' : null,
    );
  }
}

class _Base implements StorageProvider {
  @override
  String get id => 'p';
  @override
  String get displayName => 'P';
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

void main() {
  oauthConfigTests();
  late AppDatabase db;
  late InMemorySecretStore secrets;
  late _CountingProvider provider;
  late AccountService svc;
  var now = DateTime.utc(2026);

  TokenSet tokens({String account = 'a', String refresh = 'r0'}) => TokenSet(
    refreshToken: refresh,
    access: AccessToken(
      token: 'initial',
      expiresAt: DateTime.utc(2026, 1, 1, 1),
    ),
    accountId: account,
    displayName: 'Acc $account',
  );

  setUp(() {
    db = AppDatabase.memory();
    secrets = InMemorySecretStore();
    provider = _CountingProvider();
    now = DateTime.utc(2026);
    svc = AccountService(
      db,
      secrets,
      ProviderRegistry([provider]),
      now: () => now,
    );
  });
  tearDown(() => db.close());

  test('add stores the refresh token in the secret store only', () async {
    final id = await svc.add('p', tokens());
    expect(await secrets.read(SecretStore.refreshTokenKey(id)), 'r0');
    expect((await svc.list()).single.displayName, 'Acc a');
  });

  test('reconnecting keeps the row and clears needs_reauth', () async {
    final id = await svc.add('p', tokens());
    provider.revoked = true;
    now = DateTime.utc(2026, 1, 2);
    await expectLater(svc.accessToken(id), throwsA(isA<ReauthRequired>()));
    expect((await svc.list()).single.status, AccountStatus.needsReauth);
    final id2 = await svc.add('p', tokens(refresh: 'r1'));
    expect(id2, id);
    expect((await svc.list()).single.status, AccountStatus.active);
    expect(await secrets.read(SecretStore.refreshTokenKey(id)), 'r1');
  });

  test('cached access token is reused until it nearly expires', () async {
    final id = await svc.add('p', tokens());
    expect((await svc.accessToken(id)).token, 'initial');
    expect(provider.refreshes, 0);
    now = DateTime.utc(2026, 1, 1, 0, 59, 30); // < 60s left
    expect((await svc.accessToken(id)).token, 'access-1');
    expect(provider.refreshes, 1);
  });

  test('concurrent refreshes are shared', () async {
    final id = await svc.add('p', tokens());
    now = DateTime.utc(2027);
    await Future.wait([
      svc.accessToken(id),
      svc.accessToken(id),
      svc.accessToken(id),
    ]);
    expect(provider.refreshes, 1);
  });

  test('rotated refresh tokens are persisted', () async {
    final id = await svc.add('p', tokens());
    provider.rotate = true;
    now = DateTime.utc(2027);
    await svc.accessToken(id);
    expect(await secrets.read(SecretStore.refreshTokenKey(id)), 'rotated-1');
  });

  test('missing secret marks the account for reauth', () async {
    final id = await svc.add('p', tokens());
    await secrets.delete(SecretStore.refreshTokenKey(id));
    now = DateTime.utc(2027);
    await expectLater(svc.accessToken(id), throwsA(isA<ReauthRequired>()));
    expect((await svc.list()).single.status, AccountStatus.needsReauth);
  });

  test('remove deletes the row and the secret', () async {
    final id = await svc.add('p', tokens());
    await svc.remove(id);
    expect(await svc.list(), isEmpty);
    expect(await secrets.read(SecretStore.refreshTokenKey(id)), isNull);
  });
}

void oauthConfigTests() {
  test('oauth config round-trips and trims', () async {
    final store = OAuthConfigStore(InMemorySecretStore());
    expect(await store.read('google'), isNull);
    await store.write(
      'google',
      const OAuthClientConfig(clientId: ' id ', clientSecret: ' '),
    );
    final c = (await store.read('google'))!;
    expect(c.clientId, 'id');
    expect(c.clientSecret, isNull);
    expect(
      () => store.write('google', const OAuthClientConfig(clientId: '')),
      throwsArgumentError,
    );
    await store.delete('google');
    expect(await store.read('google'), isNull);
  });
}
