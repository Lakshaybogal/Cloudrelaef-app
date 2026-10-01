import 'dart:async';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'storage_provider.dart';

const _retryStatus = {429, 500, 502, 503, 504};
const _rateLimitMarkers = ['rateLimitExceeded', 'userRateLimitExceeded'];

/// Replaced in tests so retries don't actually wait.
Future<void> Function(Duration) sleeper = (d) => Future<void>.delayed(d);

Duration _delay(int attempt, String? retryAfter) {
  final secs = retryAfter == null ? null : int.tryParse(retryAfter);
  if (secs != null) return Duration(seconds: min(secs, 60));
  final ms = min(30000, 500 * (1 << attempt)) + Random().nextInt(250);
  return Duration(milliseconds: ms);
}

bool _shouldRetry(http.Response r) =>
    _retryStatus.contains(r.statusCode) ||
    (r.statusCode == 403 && _rateLimitMarkers.any(r.body.contains));

/// Sends a request, retrying 429/5xx/rate-limit-403 and network errors with
/// exponential backoff. [send] builds a fresh request each call, because a
/// request can only be sent once.
Future<http.Response> sendWithRetry(
  Future<http.Response> Function() send, {
  int maxAttempts = 5,
}) async {
  for (var attempt = 0; ; attempt++) {
    final last = attempt == maxAttempts - 1;
    http.Response resp;
    try {
      resp = await send();
    } on http.ClientException {
      if (last) rethrow;
      await sleeper(_delay(attempt, null));
      continue;
    }
    if (last || !_shouldRetry(resp)) return resp;
    await sleeper(_delay(attempt, resp.headers['retry-after']));
  }
}

/// Throws [ProviderError] unless the response is 2xx. Never includes tokens.
void checkOk(http.Response r, String provider, String what) {
  if (r.statusCode >= 200 && r.statusCode < 300) return;
  throw ProviderError(
    '$provider $what failed (${r.statusCode})',
    status: r.statusCode,
  );
}
