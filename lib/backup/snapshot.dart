import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';

import '../data/db/database.dart';
import 'crypto.dart';

/// Builds and opens the encrypted database snapshots.
class SnapshotCodec {
  SnapshotCodec({BackupCrypto? crypto}) : _crypto = crypto ?? BackupCrypto();
  final BackupCrypto _crypto;

  /// Consistent copy of the live database (`VACUUM INTO` works while the app
  /// keeps writing), gzipped and encrypted.
  Future<Uint8List> create({
    required AppDatabase db,
    required Directory tempDir,
    required Uint8List key,
    required String snapshotId,
    required int counter,
    required String deviceId,
    required DateTime now,
  }) async {
    await tempDir.create(recursive: true);
    final copy = File('${tempDir.path}/snapshot-$snapshotId.sqlite');
    if (await copy.exists()) await copy.delete();
    try {
      await db.customStatement('VACUUM INTO ?', [copy.path]);
      final raw = await copy.readAsBytes();
      return await _crypto.seal(
        key: key,
        header: {
          'v': 1,
          'snapshot_id': snapshotId,
          'counter': counter,
          'device_id': deviceId,
          'schema_version': db.schemaVersion,
          'created_at': now.toUtc().toIso8601String(),
        },
        plaintext: gzip.encode(raw),
      );
    } finally {
      if (await copy.exists()) await copy.delete();
    }
  }

  /// Decrypts [blob] into a sqlite file under [tempDir] and sanity-checks it.
  /// Refuses snapshots written by a newer schema than this app knows.
  Future<({Map<String, Object?> header, File file})> open({
    required Uint8List blob,
    required Uint8List key,
    required Directory tempDir,
    required int supportedSchema,
  }) async {
    final opened = await _crypto.open(key: key, blob: blob);
    final schema = opened.header['schema_version'];
    if (schema is! int || schema > supportedSchema) {
      throw BackupCryptoException(
        'This backup was made by a newer version of CloudRelaef. Update the app.',
      );
    }
    final List<int> raw;
    try {
      raw = gzip.decode(opened.plaintext);
    } on FormatException {
      throw BackupCryptoException('Backup content is corrupt');
    }
    await tempDir.create(recursive: true);
    final file = File(
      '${tempDir.path}/restore-${opened.header['snapshot_id']}.sqlite',
    );
    await file.writeAsBytes(raw, flush: true);
    final probe = AppDatabase(NativeDatabase(file));
    try {
      final rows = await probe.customSelect('PRAGMA integrity_check').get();
      if (rows.length != 1 || rows.first.data.values.first != 'ok') {
        throw BackupCryptoException(
          'Backup database failed its integrity check',
        );
      }
      await probe.customSelect('SELECT count(*) FROM linked_accounts').get();
    } catch (e) {
      await probe.close();
      await file.delete();
      if (e is BackupCryptoException) rethrow;
      throw BackupCryptoException(
        'Backup database is not a CloudRelaef database',
      );
    }
    await probe.close();
    return (header: opened.header, file: file);
  }
}
