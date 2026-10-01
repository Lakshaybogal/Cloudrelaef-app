import 'package:flutter/material.dart';

import '../data/db/database.dart';
import '../services/accounts.dart';
import 'app_scope.dart';
import 'util.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onOpenAccounts});
  final VoidCallback onOpenAccounts;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.services;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage pool'),
        actions: [
          IconButton(
            tooltip: 'Sync all',
            icon: const Icon(Icons.sync),
            onPressed: () async {
              final res = await withProgress(
                context,
                'Syncing...',
                s.sync.syncAll,
              );
              app.refresh();
              if (res != null && context.mounted) {
                final failed = res.values.whereType<Exception>().length;
                toast(
                  context,
                  failed == 0
                      ? 'Synced ${res.length} account(s)'
                      : '$failed account(s) failed to sync',
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<LinkedAccount>>(
        future: s.accounts.list(),
        builder: (context, snap) {
          final accounts = snap.data;
          if (accounts == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (accounts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 48),
                    const SizedBox(height: 12),
                    const Text('No clouds connected yet.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: onOpenAccounts,
                      child: const Text('Connect an account'),
                    ),
                  ],
                ),
              ),
            );
          }
          final limited = accounts.where((a) => a.quotaTotal != null);
          final total = limited.fold<int>(0, (a, b) => a + b.quotaTotal!);
          final used = accounts.fold<int>(0, (a, b) => a + b.quotaUsed);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Combined',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        total == 0
                            ? formatBytes(used)
                            : '${formatBytes(total - used > 0 ? total - used : 0)} free',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      if (total > 0)
                        LinearProgressIndicator(
                          value: (used / total).clamp(0, 1),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        '${formatBytes(used)} used of ${total == 0 ? 'unlimited' : formatBytes(total)} '
                        'across ${accounts.length} account(s)',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (final a in accounts) _AccountCard(a),
            ],
          );
        },
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard(this.a);
  final LinkedAccount a;

  @override
  Widget build(BuildContext context) {
    final needsReauth = a.status == AccountStatus.needsReauth;
    return Card(
      child: ListTile(
        leading: Icon(
          needsReauth ? Icons.warning_amber_rounded : Icons.cloud_done_outlined,
          color: needsReauth ? Theme.of(context).colorScheme.error : null,
        ),
        title: Text(a.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              needsReauth
                  ? 'Needs reconnecting'
                  : '${a.provider} · synced ${formatAgo(a.lastSyncedAt, DateTime.now())}',
            ),
            if (a.quotaTotal != null) ...[
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: (a.quotaUsed / a.quotaTotal!).clamp(0, 1),
              ),
              const SizedBox(height: 2),
              Text(
                '${formatBytes(a.quotaUsed)} / ${formatBytes(a.quotaTotal!)}',
              ),
            ] else
              Text('${formatBytes(a.quotaUsed)} used'),
          ],
        ),
      ),
    );
  }
}
