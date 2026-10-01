import 'dart:async';
import 'dart:io';

import '../providers/storage_provider.dart';
import 'pkce.dart';

/// Receives the browser redirect. Desktop uses [LoopbackRedirect]; mobile
/// plugs in a custom-scheme / app-link implementation.
abstract class RedirectListener {
  /// The redirect URI to register at the provider and send in the request.
  Future<String> start();

  /// Completes with the query parameters of the redirect.
  Future<Map<String, String>> waitForRedirect();

  Future<void> close();
}

class OAuthException implements Exception {
  OAuthException(this.message);
  final String message;
  @override
  String toString() => 'OAuthException: $message';
}

/// Listens on `http://127.0.0.1:<random port>/` for one redirect.
class LoopbackRedirect implements RedirectListener {
  HttpServer? _server;
  final _result = Completer<Map<String, String>>();

  @override
  Future<String> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    server.listen((req) async {
      req.response
        ..headers.contentType = ContentType.html
        ..write(
          '<html><body style="font-family:sans-serif;text-align:center;margin-top:20vh">'
          '<h2>CloudRelaef</h2><p>You can close this tab and return to the app.</p>'
          '</body></html>',
        );
      await req.response.close();
      if (req.uri.queryParameters.isNotEmpty && !_result.isCompleted) {
        _result.complete(req.uri.queryParameters);
      }
    });
    return 'http://127.0.0.1:${server.port}/';
  }

  @override
  Future<Map<String, String>> waitForRedirect() => _result.future;

  @override
  Future<void> close() async => _server?.close(force: true);
}

typedef UrlLauncher = Future<void> Function(Uri url);

/// Runs the browser step of Authorization Code + PKCE and returns a token set.
class OAuthFlow {
  OAuthFlow({
    required this.provider,
    required this.listener,
    required this.launch,
    this.timeout = const Duration(minutes: 5),
  });

  final StorageProvider provider;
  final RedirectListener listener;
  final UrlLauncher launch;
  final Duration timeout;

  Future<TokenSet> connect() async {
    final pkce = Pkce.generate();
    final state = generateState();
    final redirectUri = await listener.start();
    try {
      await launch(
        provider.authUrl(
          state: state,
          redirectUri: redirectUri,
          codeChallenge: pkce.challenge,
        ),
      );
      final params = await listener.waitForRedirect().timeout(
        timeout,
        onTimeout: () => throw OAuthException('Sign-in timed out'),
      );
      if (params['state'] != state) {
        throw OAuthException('State mismatch; sign-in rejected');
      }
      final error = params['error'];
      if (error != null) throw OAuthException('Provider returned: $error');
      final code = params['code'];
      if (code == null) throw OAuthException('No authorization code returned');
      return await provider.exchangeCode(
        code: code,
        redirectUri: redirectUri,
        verifier: pkce.verifier,
      );
    } finally {
      await listener.close();
    }
  }
}
