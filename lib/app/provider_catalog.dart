import 'package:http/http.dart' as http;

import '../auth/oauth_config_store.dart';
import '../providers/dropbox.dart';
import '../providers/google_drive.dart';
import '../providers/onedrive.dart';
import '../providers/registry.dart';
import '../providers/storage_provider.dart';

/// Redirect used by every provider on desktop and mobile. Register exactly
/// this in your OAuth app.
const oauthRedirectPort = 53682;
const oauthRedirectUri = 'http://localhost:$oauthRedirectPort/';

class ProviderInfo {
  const ProviderInfo({
    required this.id,
    required this.title,
    required this.consoleUrl,
    required this.steps,
    required this.askSecret,
  });
  final String id;
  final String title;
  final String consoleUrl;
  final List<String> steps;

  /// Google "Desktop app" clients still require a client secret for token
  /// exchange. It is not confidential for installed apps.
  final bool askSecret;
}

const providerInfos = <ProviderInfo>[
  ProviderInfo(
    id: 'google',
    title: 'Google Drive',
    consoleUrl: 'https://console.cloud.google.com/apis/credentials',
    askSecret: true,
    steps: [
      'Open the Google Cloud console, create a project and enable the "Google Drive API".',
      'OAuth consent screen: choose External, add yourself as a test user. '
          'Then click "Publish app" (In production) or your sign-in expires every 7 days.',
      'Credentials -> Create credentials -> OAuth client ID -> type "Desktop app".',
      'Copy the Client ID and Client secret into the fields below.',
    ],
  ),
  ProviderInfo(
    id: 'onedrive',
    title: 'OneDrive (personal)',
    consoleUrl: 'https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade',
    askSecret: false,
    steps: [
      'Open Microsoft Entra -> App registrations -> New registration.',
      'Supported account types: "Personal Microsoft accounts only".',
      'Redirect URI: platform "Mobile and desktop applications", value $oauthRedirectUri',
      'API permissions: Microsoft Graph -> Delegated -> Files.ReadWrite.AppFolder, offline_access, User.Read.',
      'Copy the Application (client) ID into the field below. No secret needed.',
    ],
  ),
  ProviderInfo(
    id: 'dropbox',
    title: 'Dropbox',
    consoleUrl: 'https://www.dropbox.com/developers/apps',
    askSecret: false,
    steps: [
      'Open the Dropbox App Console -> Create app -> Scoped access -> "App folder".',
      'Permissions tab: tick files.metadata.read/write, files.content.read/write, account_info.read. Submit.',
      'Settings tab: add the redirect URI $oauthRedirectUri',
      'Copy the App key into the field below. No secret needed.',
    ],
  ),
];

/// Creates providers on demand from the user's own OAuth apps. A provider
/// without keys is "not configured" and unavailable.
class ProviderCatalog extends ProviderRegistry {
  ProviderCatalog(this._configs, {this.httpClient}) : super(const []);

  final OAuthConfigStore _configs;
  final http.Client? httpClient;
  final Map<String, OAuthClientConfig> _cache = {};

  static List<String> get allIds => [for (final i in providerInfos) i.id];

  @override
  List<String> get ids => allIds;

  Future<void> load() async {
    for (final id in allIds) {
      final c = await _configs.read(id);
      if (c != null) _cache[id] = c;
    }
  }

  bool isConfigured(String id) => _cache.containsKey(id);

  OAuthClientConfig? config(String id) => _cache[id];

  Future<void> save(String id, OAuthClientConfig c) async {
    await _configs.write(id, c);
    final saved = await _configs.read(id);
    if (saved != null) _cache[id] = saved;
  }

  Future<void> clear(String id) async {
    await _configs.delete(id);
    _cache.remove(id);
  }

  @override
  StorageProvider get(String id) {
    final cfg = _cache[id];
    if (cfg == null) {
      throw ProviderError('$id is not set up: add your OAuth client ID first');
    }
    return switch (id) {
      'google' => GoogleDriveProvider(cfg, client: httpClient),
      'onedrive' => OneDriveProvider(cfg, client: httpClient),
      'dropbox' => DropboxProvider(cfg, client: httpClient),
      _ => throw ArgumentError.value(id, 'id', 'Unknown provider'),
    };
  }
}
