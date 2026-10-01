import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

String _b64url(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

String _random(int bytes, Random rng) =>
    _b64url([for (var i = 0; i < bytes; i++) rng.nextInt(256)]);

class Pkce {
  Pkce._(this.verifier, this.challenge);

  /// 64 random bytes -> 86 chars (RFC 7636 allows 43..128).
  factory Pkce.generate([Random? rng]) {
    final v = _random(64, rng ?? Random.secure());
    return Pkce._(v, challengeFor(v));
  }

  final String verifier;
  final String challenge;

  /// S256: base64url(sha256(verifier)) without padding.
  static String challengeFor(String verifier) =>
      _b64url(sha256.convert(ascii.encode(verifier)).bytes);
}

/// Unguessable value tying the redirect back to the request.
String generateState([Random? rng]) => _random(24, rng ?? Random.secure());
