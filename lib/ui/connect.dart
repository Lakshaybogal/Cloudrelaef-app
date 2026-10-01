import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/provider_catalog.dart';
import '../auth/oauth_flow.dart';
import '../providers/storage_provider.dart';
import 'app_scope.dart';
import 'util.dart';

/// Asks for the user's own OAuth client ID (bring-your-own-keys) when the
/// provider is not set up yet, then signs in. Returns the account id or null.
Future<int?> connectProvider(BuildContext context, String providerId) async {
  final app = AppScope.of(context);
  final services = app.services;
  if (!services.catalog.isConfigured(providerId)) {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProviderKeysScreen(providerId: providerId),
      ),
    );
    if (saved != true || !context.mounted) return null;
  }
  return withProgress<int>(
    context,
    'Waiting for you to sign in in the browser...',
    () async {
      final provider = services.catalog.get(providerId);
      final flow = OAuthFlow(
        provider: provider,
        listener: LoopbackRedirect(
          port: oauthRedirectPort,
          redirectHost: 'localhost',
        ),
        launch: (url) async {
          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
            throw OAuthException('Could not open the browser');
          }
        },
      );
      final tokens = await flow.connect();
      final id = await services.accounts.add(providerId, tokens);
      try {
        await services.sync.syncAccount(id);
      } on ProviderError {
        // The account is connected even if the first sync fails; retry later.
      }
      app.refresh();
      return id;
    },
  );
}

/// Step-by-step instructions plus the fields for the client ID.
class ProviderKeysScreen extends StatefulWidget {
  const ProviderKeysScreen({super.key, required this.providerId});
  final String providerId;

  @override
  State<ProviderKeysScreen> createState() => _ProviderKeysScreenState();
}

class _ProviderKeysScreenState extends State<ProviderKeysScreen> {
  final _id = TextEditingController();
  final _secret = TextEditingController();
  late final ProviderInfo info = providerInfos.firstWhere(
    (i) => i.id == widget.providerId,
  );

  @override
  void initState() {
    super.initState();
    final existing = AppScope.servicesOf(context).catalog
        .config(widget.providerId);
    _id.text = existing?.clientId ?? '';
    _secret.text = existing?.clientSecret ?? '';
  }

  Future<void> _save() async {
    if (_id.text.trim().isEmpty) {
      toast(context, 'Enter the client ID');
      return;
    }
    await AppScope.servicesOf(context).catalog.save(
      widget.providerId,
      OAuthClientConfig(
        clientId: _id.text,
        clientSecret: info.askSecret ? _secret.text : null,
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Set up ${info.title}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'CloudRelaef has no server, so it signs in with an app you create '
            'for yourself. It takes about five minutes, once.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < info.steps.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 11,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(info.steps[i])),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open console'),
                onPressed: () => launchUrl(
                  Uri.parse(info.consoleUrl),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copy redirect URI'),
                onPressed: () async {
                  await Clipboard.setData(
                    const ClipboardData(text: oauthRedirectUri),
                  );
                  if (context.mounted) {
                    toast(context, 'Copied $oauthRedirectUri');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _id,
            decoration: const InputDecoration(
              labelText: 'Client ID',
              border: OutlineInputBorder(),
            ),
          ),
          if (info.askSecret) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _secret,
              decoration: const InputDecoration(
                labelText: 'Client secret',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Save')),
          const SizedBox(height: 8),
          Text(
            'Stored only in this device\'s secure storage. Never sent anywhere except to ${info.title}.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
