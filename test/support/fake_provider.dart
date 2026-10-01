import 'dart:async';

import 'package:cloudrelaef/providers/storage_provider.dart';

/// In-memory provider used by tests. Also the reference behaviour that the
/// shared adapter contract suite (M3) will hold real adapters to.
class FakeProvider implements StorageProvider {
  FakeProvider({this.id = 'fake', this.total = 1000});

  @override
  final String id;
  @override
  String get displayName => 'Fake';
  final int? total;

  /// When true, delete() fails like a provider outage.
  bool failDeletes = false;

  /// When true, upload() fails like a provider outage.
  bool failUploads = false;
  final Map<String, List<int>> _bytes = {};
  final Map<String, RemoteFile> _files = {};
  int _next = 0;

  static final _token = AccessToken(token: 't', expiresAt: DateTime.utc(2100));

  @override
  Uri authUrl({
    required String state,
    required String redirectUri,
    required String codeChallenge,
  }) => Uri.https('fake.example', '/auth', {
    'client_id': 'fake-client',
    'state': state,
    'redirect_uri': redirectUri,
    'code_challenge': codeChallenge,
  });

  @override
  Future<TokenSet> exchangeCode({
    required String code,
    required String redirectUri,
    required String verifier,
  }) async => TokenSet(
    refreshToken: 'refresh-$code',
    access: _token,
    accountId: 'acct-$code',
    displayName: 'Fake $code',
  );

  @override
  Future<AccessToken> refreshToken(String refreshToken) async => _token;

  @override
  Future<Quota> getQuota(AccessToken access) async => Quota(
    total: total,
    used: _bytes.values.fold<int>(0, (a, b) => a + b.length),
  );

  @override
  Future<FilePage> listFiles(AccessToken access, {String? cursor}) async {
    final all = _files.values.toList()
      ..sort((a, b) => a.remoteId.compareTo(b.remoteId));
    final start = cursor == null ? 0 : int.parse(cursor);
    const pageSize = 2;
    final page = all.skip(start).take(pageSize).toList();
    final end = start + page.length;
    return FilePage(files: page, nextCursor: end < all.length ? '$end' : null);
  }

  @override
  Future<RemoteFile> upload(
    AccessToken access, {
    required String name,
    required int size,
    required String mime,
    required Stream<List<int>> data,
  }) async {
    if (failUploads) throw ProviderError('outage', status: 503);
    final buf = <int>[];
    await for (final chunk in data) {
      buf.addAll(chunk);
    }
    if (buf.length != size) {
      throw ProviderError('size mismatch: ${buf.length} != $size');
    }
    final used = _bytes.values.fold<int>(0, (a, b) => a + b.length);
    if (total != null && used + size > total!) {
      throw ProviderError('quota exceeded', status: 507);
    }
    final id = 'f${(_next++).toString().padLeft(4, '0')}';
    _bytes[id] = buf;
    return _files[id] = RemoteFile(
      remoteId: id,
      name: name,
      size: size,
      mime: mime,
      modifiedAt: DateTime.utc(2026),
      path: '/$name',
    );
  }

  @override
  Stream<List<int>> download(AccessToken access, String remoteId) {
    final b = _bytes[remoteId];
    if (b == null) {
      return Stream.error(ProviderError('not found', status: 404));
    }
    return Stream.fromIterable([
      for (var i = 0; i < b.length; i += 3)
        b.sublist(i, i + 3 > b.length ? b.length : i + 3),
    ]);
  }

  @override
  Future<void> delete(AccessToken access, String remoteId) async {
    if (failDeletes) throw ProviderError('outage', status: 503);
    if (_files.remove(remoteId) == null) {
      throw ProviderError('not found', status: 404);
    }
    _bytes.remove(remoteId);
  }

  @override
  Future<RemoteFile> rename(
    AccessToken access,
    String remoteId,
    String newName,
  ) async {
    final f = _files[remoteId];
    if (f == null) throw ProviderError('not found', status: 404);
    if (_files.values.any((o) => o.remoteId != remoteId && o.name == newName)) {
      throw ProviderError('name clash', status: 409);
    }
    return _files[remoteId] = RemoteFile(
      remoteId: f.remoteId,
      name: newName,
      size: f.size,
      mime: f.mime,
      modifiedAt: f.modifiedAt,
      path: '/$newName',
    );
  }
}
