import 'dart:io';
import 'dart:math';

import '../data/secure/secret_store.dart';
import '../services/accounts.dart';
import '../services/files.dart';
import '../services/folders.dart';
import '../services/settings.dart';
import 'webdav_server.dart';

class WebDavSettingKeys {
  static const enabled = 'webdav_enabled';
  static const port = 'webdav_port';
}

/// Owns the optional WebDAV server: on/off switch, port, password, lifecycle.
/// Off by default; loopback only.
class WebDavManager {
  WebDavManager({
    required this.settings,
    required this.secrets,
    required this.files,
    required this.folders,
    required this.accounts,
    required this.tempDir,
    Random? rng,
  }) : _rng = rng ?? Random.secure();

  final SettingsStore settings;
  final SecretStore secrets;
  final FileService files;
  final FolderService folders;
  final AccountService accounts;
  final Directory tempDir;
  final Random _rng;

  static const defaultPort = 8765;
  static const username = 'cloudrelaef';
  static const _passwordKey = 'webdav_password';
  static const _alphabet =
      'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  WebDavServer? _server;

  bool get running => _server?.running ?? false;

  /// The address to enter in a file manager, once running.
  String? get url => running ? 'http://127.0.0.1:${_server!.boundPort}/' : null;

  Future<bool> isEnabled() async =>
      await settings.get(WebDavSettingKeys.enabled) == '1';

  Future<int> port() async =>
      await settings.getInt(WebDavSettingKeys.port) ?? defaultPort;

  /// Generated on first use and kept in the keystore (not in the database,
  /// so it never appears in a backup).
  Future<String> password() async {
    var pw = await secrets.read(_passwordKey);
    if (pw == null) {
      pw = _generate();
      await secrets.write(_passwordKey, pw);
    }
    return pw;
  }

  /// New password; if the server runs it restarts so the old one stops working.
  Future<String> regeneratePassword() async {
    final pw = _generate();
    await secrets.write(_passwordKey, pw);
    if (running) {
      await stop();
      await start();
    }
    return pw;
  }

  String _generate() => List.generate(
    24,
    (_) => _alphabet[_rng.nextInt(_alphabet.length)],
  ).join();

  Future<void> setPort(int port) async {
    if (port < 1024 || port > 65535) {
      throw ArgumentError('Port must be between 1024 and 65535');
    }
    await settings.setInt(WebDavSettingKeys.port, port);
    if (running) {
      await stop();
      await start();
    }
  }

  /// Starts the server and remembers that it should start next time.
  Future<void> start() async {
    if (running) return;
    final server = WebDavServer(
      files: files,
      folders: folders,
      accounts: accounts,
      password: await password(),
      tempDir: tempDir,
      port: await port(),
    );
    try {
      await server.start();
    } on SocketException {
      throw StateError(
        'Port ${await port()} is already in use. Pick another one.',
      );
    }
    _server = server;
    await settings.set(WebDavSettingKeys.enabled, '1');
  }

  Future<void> stop({bool remember = true}) async {
    await _server?.stop();
    _server = null;
    if (remember) await settings.set(WebDavSettingKeys.enabled, '0');
  }

  /// App start: bring the server back if it was on. A busy port must not
  /// stop the app from opening.
  Future<void> restoreState() async {
    if (!await isEnabled()) return;
    try {
      await start();
    } on StateError {
      // Left enabled; the Drive screen shows it as not running.
    }
  }

  /// Shuts the server without changing the saved on/off state (used when the
  /// service graph is replaced after a restore).
  Future<void> dispose() => stop(remember: false);
}
