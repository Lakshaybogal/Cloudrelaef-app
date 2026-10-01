/// One implementation per cloud. Core code depends only on this interface and
/// must never import a concrete provider.
library;

/// A provider call failed. Messages must never contain tokens.
class ProviderError implements Exception {
  ProviderError(this.message, {this.status});
  final String message;
  final int? status;

  @override
  String toString() => 'ProviderError($status): $message';
}

/// The file exists but cannot be managed (e.g. Google Docs have no bytes).
class UnsupportedFile extends ProviderError {
  UnsupportedFile(super.message, {super.status});
}

/// The saved change cursor is no longer valid; do a full listing again.
class CursorExpired extends ProviderError {
  CursorExpired(super.message, {super.status});
}

/// The refresh token is invalid, revoked or expired; the user must reconnect.
class ReauthRequired extends ProviderError {
  ReauthRequired(super.message, {super.status});
}

class AccessToken {
  const AccessToken({
    required this.token,
    required this.expiresAt,
    this.newRefreshToken,
  });
  final String token;
  final DateTime expiresAt;

  /// Set when the provider rotates refresh tokens (Microsoft).
  final String? newRefreshToken;
}

class TokenSet {
  const TokenSet({
    required this.refreshToken,
    required this.access,
    required this.accountId,
    required this.displayName,
  });
  final String refreshToken;
  final AccessToken access;
  final String accountId;
  final String displayName;
}

class Quota {
  const Quota({required this.total, required this.used});

  /// null = unlimited or unknown.
  final int? total;
  final int used;
}

class RemoteFile {
  const RemoteFile({
    required this.remoteId,
    required this.name,
    required this.size,
    required this.mime,
    required this.modifiedAt,
    required this.path,
    this.hash,
  });
  final String remoteId;
  final String name;
  final int size;
  final String mime;
  final String? hash;
  final DateTime modifiedAt;
  final String path;
}

class FilePage {
  const FilePage({required this.files, this.nextCursor});
  final List<RemoteFile> files;
  final String? nextCursor;
}

/// OAuth endpoints are described per provider; the PKCE flow itself lives in
/// the auth layer (M2).
abstract class StorageProvider {
  String get id;

  Uri authUrl({
    required String clientId,
    required String state,
    required String redirectUri,
    required String codeChallenge,
  });

  Future<TokenSet> exchangeCode({
    required String clientId,
    required String code,
    required String redirectUri,
    required String verifier,
  });

  Future<AccessToken> refreshToken({
    required String clientId,
    required String refreshToken,
  });

  Future<Quota> getQuota(AccessToken access);

  /// One page per call; pass [FilePage.nextCursor] back until it is null.
  Future<FilePage> listFiles(AccessToken access, {String? cursor});

  /// Streams [size] bytes to the provider using chunked/resumable upload.
  Future<RemoteFile> upload(
    AccessToken access, {
    required String name,
    required int size,
    required String mime,
    required Stream<List<int>> data,
  });

  Stream<List<int>> download(AccessToken access, String remoteId);

  Future<void> delete(AccessToken access, String remoteId);

  /// Renames in place (same folder, same id). A name clash throws
  /// [ProviderError] with status 409 where the provider forbids duplicates.
  Future<RemoteFile> rename(
    AccessToken access,
    String remoteId,
    String newName,
  );
}
