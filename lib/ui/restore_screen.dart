import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../app/provider_catalog.dart';
import '../backup/crypto.dart';
import 'app_scope.dart';
import 'connect.dart';
import 'util.dart';

/// Restore on a new device: recovery key -> connect any cloud -> restore.
class RestoreScreen extends StatefulWidget {
  const RestoreScreen({super.key});

  @override
  State<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends State<RestoreScreen> {
  final _key = TextEditingController();

  Future<void> _restore() async {
    final app = AppScope.of(context);
    final nav = Navigator.of(context);
    Uint8List key;
    try {
      key = RecoveryKey.decode(_key.text);
    } on BackupCryptoException catch (e) {
      toast(context, e.message);
      return;
    }
    final outcome = await withProgress(context, 'Restoring...', () async {
      return app.services.restore.restoreLatest(
        accounts: app.services.accounts,
        key: key,
      );
    });
    if (outcome == null) return;
    app.replaceServices(app.services.rebuild());
    if (!mounted) return;
    toast(
      context,
      outcome.accountsNeedingReauth == 0
          ? 'Restored.'
          : 'Restored. Reconnect ${outcome.accountsNeedingReauth} account(s) under Accounts.',
    );
    nav.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Restore')),
      body: FutureBuilder(
        future: app.services.accounts.list(),
        builder: (context, snap) {
          final accounts = snap.data ?? const [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('1. Enter your recovery key'),
              const SizedBox(height: 8),
              TextField(
                controller: _key,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'ABCD-EFGH-...',
                ),
              ),
              const SizedBox(height: 20),
              const Text('2. Connect any cloud that holds a backup'),
              const SizedBox(height: 8),
              for (final id in ProviderCatalog.allIds)
                ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: Text(
                    providerInfos.firstWhere((i) => i.id == id).title,
                  ),
                  trailing: const Icon(Icons.add),
                  onTap: () async {
                    await connectProvider(context, id);
                    if (mounted) setState(() {});
                  },
                ),
              if (accounts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Connected: ${accounts.map((a) => a.displayName).join(', ')}',
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: accounts.isEmpty ? null : _restore,
                child: const Text('3. Restore'),
              ),
            ],
          );
        },
      ),
    );
  }
}
