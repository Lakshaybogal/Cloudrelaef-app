import 'package:flutter/material.dart';

import '../app/provider_catalog.dart';
import '../data/db/database.dart';
import '../services/accounts.dart';
import 'app_scope.dart';
import 'connect.dart';
import 'util.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.services;
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      body: FutureBuilder<List<LinkedAccount>>(
        future: s.accounts.list(),
        builder: (context, snap) {
          final accounts = snap.data ?? const <LinkedAccount>[];
          return ListView(
            children: [
              for (final a in accounts)
                ListTile(
                  leading: Icon(
                    a.status == AccountStatus.active
                        ? Icons.cloud_done_outlined
                        : Icons.warning_amber_rounded,
                  ),
                  title: Text(a.displayName),
                  subtitle: Text(
                    a.status == AccountStatus.active
                        ? providerInfos
                              .firstWhere(
                                (i) => i.id == a.provider,
                                orElse: () => providerInfos.first,
                              )
                              .title
                        : 'Needs reconnecting',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) => _onAction(context, a, v),
                    itemBuilder: (_) => [
                      if (a.status == AccountStatus.needsReauth)
                        const PopupMenuItem(
                          value: 'reconnect',
                          child: Text('Reconnect'),
                        ),
                      const PopupMenuItem(
                        value: 'sync',
                        child: Text('Sync now'),
                      ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Text('Remove'),
                      ),
                    ],
                  ),
                ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('Add an account'),
              ),
              for (final info in providerInfos)
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: Text(info.title),
                  subtitle: Text(
                    s.catalog.isConfigured(info.id)
                        ? 'Your OAuth app is set up'
                        : 'Needs your own OAuth app (one-time)',
                  ),
                  trailing: s.catalog.isConfigured(info.id)
                      ? IconButton(
                          tooltip: 'Edit keys',
                          icon: const Icon(Icons.key),
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<bool>(
                                builder: (_) =>
                                    ProviderKeysScreen(providerId: info.id),
                              ),
                            );
                            app.refresh();
                          },
                        )
                      : null,
                  onTap: () async {
                    await connectProvider(context, info.id);
                    app.refresh();
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    LinkedAccount a,
    String action,
  ) async {
    final app = AppScope.of(context);
    final s = app.services;
    switch (action) {
      case 'reconnect':
        await connectProvider(context, a.provider);
      case 'sync':
        await withProgress(
          context,
          'Syncing ${a.displayName}...',
          () => s.sync.syncAccount(a.id),
        );
      case 'remove':
        final ok = await confirm(
          context,
          title: 'Remove ${a.displayName}?',
          message:
              'Your files stay in that cloud. They disappear from this '
              'pool until you connect the account again.',
          action: 'Remove',
        );
        if (ok) await s.accounts.remove(a.id);
    }
    app.refresh();
  }
}
