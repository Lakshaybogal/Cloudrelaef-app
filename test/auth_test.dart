import 'dart:io';
import 'dart:math';

import 'package:cloudrelaef/auth/oauth_flow.dart';
import 'package:cloudrelaef/auth/pkce.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_provider.dart';

class _FakeRedirect implements RedirectListener {
  _FakeRedirect(this.respond);
  final Map<String, String> Function(Uri authUrl) respond;
  Uri? authUrl;
  bool closed = false;
  @override
  Future<String> start() async => 'http://127.0.0.1:9/';
  @override
  Future<Map<String, String>> waitForRedirect() async => respond(authUrl!);
  @override
  Future<void> close() async => closed = true;
}

void main() {
  test('PKCE matches the RFC 7636 test vector', () {
    expect(
      Pkce.challengeFor('dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk'),
      'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
    );
  });

  test('generated verifier is valid and unique', () {
    final a = Pkce.generate();
    final b = Pkce.generate();
    expect(a.verifier.length, inInclusiveRange(43, 128));
    expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(a.verifier), isTrue);
    expect(a.verifier, isNot(b.verifier));
    expect(Pkce.challengeFor(a.verifier), a.challenge);
    expect(generateState(Random(1)), isNot(generateState(Random(2))));
  });

  test('flow succeeds when state matches', () async {
    late _FakeRedirect listener;
    listener = _FakeRedirect(
      (u) => {'code': 'abc', 'state': u.queryParameters['state']!},
    );
    final flow = OAuthFlow(
      provider: FakeProvider(),
      listener: listener,
      launch: (u) async => listener.authUrl = u,
    );
    final tokens = await flow.connect();
    expect(tokens.accountId, 'acct-abc');
    expect(listener.closed, isTrue);
  });

  test('flow rejects a wrong state', () async {
    late _FakeRedirect listener;
    listener = _FakeRedirect((u) => {'code': 'abc', 'state': 'evil'});
    final flow = OAuthFlow(
      provider: FakeProvider(),
      listener: listener,
      launch: (u) async => listener.authUrl = u,
    );
    await expectLater(flow.connect(), throwsA(isA<OAuthException>()));
    expect(listener.closed, isTrue);
  });

  test('flow surfaces provider errors and missing codes', () async {
    for (final params in [
      {'error': 'access_denied'},
      <String, String>{},
    ]) {
      late _FakeRedirect listener;
      listener = _FakeRedirect(
        (u) => {...params, 'state': u.queryParameters['state']!},
      );
      final flow = OAuthFlow(
        provider: FakeProvider(),
        listener: listener,
        launch: (u) async => listener.authUrl = u,
      );
      await expectLater(flow.connect(), throwsA(isA<OAuthException>()));
    }
  });

  test('flow times out', () async {
    final listener = _HangingRedirect();
    final flow = OAuthFlow(
      provider: FakeProvider(),
      listener: listener,
      launch: (_) async {},
      timeout: const Duration(milliseconds: 50),
    );
    await expectLater(flow.connect(), throwsA(isA<OAuthException>()));
  });

  test('loopback listener receives a real redirect', () async {
    final l = LoopbackRedirect();
    final uri = await l.start();
    final client = HttpClient();
    final req = await client.getUrl(Uri.parse('$uri?code=c1&state=s1'));
    final resp = await req.close();
    await resp.drain<void>();
    expect(await l.waitForRedirect(), {'code': 'c1', 'state': 's1'});
    await l.close();
    client.close();
  });
}

class _HangingRedirect implements RedirectListener {
  @override
  Future<String> start() async => 'http://127.0.0.1:9/';
  @override
  Future<Map<String, String>> waitForRedirect() =>
      Future.delayed(const Duration(seconds: 5), () => {});
  @override
  Future<void> close() async {}
}
