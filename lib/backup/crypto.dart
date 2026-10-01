import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hash;
import 'package:cryptography/cryptography.dart';

class BackupCryptoException implements Exception {
  BackupCryptoException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The 32-byte master key and its human-friendly recovery code.
class RecoveryKey {
  RecoveryKey._();

  static Uint8List generate([Random? rng]) {
    final r = rng ?? Random.secure();
    return Uint8List.fromList([for (var i = 0; i < 32; i++) r.nextInt(256)]);
  }

  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  /// Base32 of key + 1 checksum byte, in groups of four:
  /// `ABCD-EFGH-...` (55 characters plus dashes).
  static String encode(Uint8List key) {
    if (key.length != 32) throw ArgumentError('Key must be 32 bytes');
    final data = [...key, hash.sha256.convert(key).bytes.first];
    final sb = StringBuffer();
    var buffer = 0;
    var bits = 0;
    for (final byte in data) {
      buffer = (buffer << 8) | byte;
      bits += 8;
      while (bits >= 5) {
        sb.write(_alphabet[(buffer >> (bits - 5)) & 31]);
        bits -= 5;
      }
      buffer &= (1 << bits) - 1;
    }
    if (bits > 0) sb.write(_alphabet[(buffer << (5 - bits)) & 31]);
    final s = sb.toString();
    return [
      for (var i = 0; i < s.length; i += 4)
        s.substring(i, min(i + 4, s.length)),
    ].join('-');
  }

  /// Accepts dashes, spaces and lower case. Throws on a typo (checksum).
  static Uint8List decode(String code) {
    final clean = code.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    var buffer = 0;
    var bits = 0;
    final out = <int>[];
    for (final ch in clean.split('')) {
      final v = _alphabet.indexOf(ch);
      if (v < 0) {
        throw BackupCryptoException('Invalid character in recovery key');
      }
      buffer = (buffer << 5) | v;
      bits += 5;
      if (bits >= 8) {
        out.add((buffer >> (bits - 8)) & 255);
        bits -= 8;
        buffer &= (1 << bits) - 1;
      }
    }
    if (out.length != 33) {
      throw BackupCryptoException('Recovery key has the wrong length');
    }
    final key = Uint8List.fromList(out.sublist(0, 32));
    if (hash.sha256.convert(key).bytes.first != out[32]) {
      throw BackupCryptoException('Recovery key has a typo (checksum failed)');
    }
    return key;
  }
}

/// AES-256-GCM with a fresh random 96-bit nonce per snapshot. The header is
/// authenticated as associated data, so it cannot be swapped or edited.
class BackupCrypto {
  BackupCrypto([Random? rng]) : _rng = rng ?? Random.secure();
  final Random _rng;
  final _aes = AesGcm.with256bits();

  static const _magic = [0x43, 0x52, 0x42, 0x31]; // "CRB1"

  Future<Uint8List> seal({
    required Uint8List key,
    required Map<String, Object?> header,
    required List<int> plaintext,
  }) async {
    final headerBytes = utf8.encode(jsonEncode(header));
    final nonce = [for (var i = 0; i < 12; i++) _rng.nextInt(256)];
    final box = await _aes.encrypt(
      plaintext,
      secretKey: SecretKey(key),
      nonce: nonce,
      aad: headerBytes,
    );
    final lenBytes = ByteData(4)..setUint32(0, headerBytes.length);
    return Uint8List.fromList([
      ..._magic,
      ...lenBytes.buffer.asUint8List(),
      ...headerBytes,
      ...nonce,
      ...box.cipherText,
      ...box.mac.bytes,
    ]);
  }

  /// Reads the (unauthenticated) header without the key, e.g. to show a
  /// snapshot list. Authenticity is only established by [open].
  static Map<String, Object?> peekHeader(Uint8List blob) => _split(blob).header;

  Future<({Map<String, Object?> header, Uint8List plaintext})> open({
    required Uint8List key,
    required Uint8List blob,
  }) async {
    final p = _split(blob);
    try {
      final clear = await _aes.decrypt(
        SecretBox(p.cipher, nonce: p.nonce, mac: Mac(p.mac)),
        secretKey: SecretKey(key),
        aad: p.headerBytes,
      );
      return (header: p.header, plaintext: Uint8List.fromList(clear));
    } on SecretBoxAuthenticationError {
      throw BackupCryptoException(
        'Wrong recovery key, or the backup is damaged',
      );
    }
  }

  static ({
    Map<String, Object?> header,
    List<int> headerBytes,
    List<int> nonce,
    List<int> cipher,
    List<int> mac,
  })
  _split(Uint8List blob) {
    if (blob.length < 4 + 4 + 12 + 16 ||
        !_magic.asMap().entries.every((e) => blob[e.key] == e.value)) {
      throw BackupCryptoException('Not a CloudRelaef backup file');
    }
    final headerLen = ByteData.sublistView(blob, 4, 8).getUint32(0);
    final hStart = 8;
    final hEnd = hStart + headerLen;
    if (headerLen > 65536 || hEnd + 12 + 16 > blob.length) {
      throw BackupCryptoException('Backup file is truncated or corrupt');
    }
    final headerBytes = blob.sublist(hStart, hEnd);
    Map<String, Object?> header;
    try {
      header = (jsonDecode(utf8.decode(headerBytes)) as Map)
          .cast<String, Object?>();
    } catch (_) {
      throw BackupCryptoException('Backup header is corrupt');
    }
    return (
      header: header,
      headerBytes: headerBytes,
      nonce: blob.sublist(hEnd, hEnd + 12),
      cipher: blob.sublist(hEnd + 12, blob.length - 16),
      mac: blob.sublist(blob.length - 16),
    );
  }
}
