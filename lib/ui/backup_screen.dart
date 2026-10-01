import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../backup/backup_service.dart';
import '../backup/crypto.dart';
import '../data/db/database.dart';
import '../services/settings.dart';
import 'app_scope.dart';
import 'util.dart';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  Future<void> _backup(BuildContext context, {bool force = false}) async {
    final app = AppScope.of(context);
    // withProgress reports other errors itself; a conflict needs a decision,
    // so it is returned as a value instead of thrown.
    final outcome =
        await withProgress<(List<CloudBackupResult>?, BackupConflict?)>(
          context,
          'Backing up...',
          () async {
            try {
              return (await app.services.backup.backupNow(force: force), null);
            } on BackupConflict catch (c) {
              return (null, c);
            }
          },
        );
    app.refresh();
    if (outcome == null || !context.mounted) return;
    final (res, conflict) = outcome;
    if (conflict != null) {
      final overwrite = await confirm(
        context,
        title: 'Another device is ahead',
        message:
            '$conflict\n\nBacking up now continues after it. If that other '
            "device's changes matter, restore instead (choose Restore on the "
            'setup screen of a fresh install).',
        action: 'Back up anyway',
      );
      if (overwrite && context.mounted) await _backup(context, force: true);
      return;
    }
    if (res!.isEmpty) {
      toast(context, 'Connect an account first');
    } else {
      final ok = res.where((r) => r.ok).length;
      toast(
        context,
        ok == res.length
            ? 'Backed up to $ok cloud(s)'
            : 'Backed up to $ok of ${res.length} clouds; see below',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.services;
    return Scaffold(
      appBar: AppBar(title: const Text('Backup')),
      body: FutureBuilder(
        future: Future.wait([
          s.backup.lastSuccess(),
          s.host.db.select(s.host.db.backupRuns).get(),
          s.accounts.list(),
          s.settings.getInt(SettingKeys.backupIntervalHours),
        ]),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final last = snap.data![0] as DateTime?;
          final runs = (snap.data![1] as List<BackupRun>)
            ..sort((a, b) => b.at.compareTo(a.at));
          final accounts = snap.data![2] as List<LinkedAccount>;
          final hours =
              (snap.data![3] as int?) ?? BackupService.defaultIntervalHours;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last backup: ${formatAgo(last?.toLocal(), DateTime.now())}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'An encrypted copy of your index (names, folders, settings) is '
                        'written to every connected cloud. Your files themselves are '
                        'not copied. No passwords or tokens are included.',
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        icon: const Icon(Icons.backup_outlined),
                        label: const Text('Back up now'),
                        onPressed: () => _backup(context),
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                title: const Text('Back up automatically every'),
                trailing: DropdownButton<int>(
                  value: const [1, 6, 12, 24].contains(hours) ? hours : 6,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 hour')),
                    DropdownMenuItem(value: 6, child: Text('6 hours')),
                    DropdownMenuItem(value: 12, child: Text('12 hours')),
                    DropdownMenuItem(value: 24, child: Text('24 hours')),
                  ],
                  onChanged: (v) async {
                    if (v == null) return;
                    await s.settings.setInt(SettingKeys.backupIntervalHours, v);
                    app.refresh();
                  },
                ),
                subtitle: const Text('While the app is open'),
              ),
              ListTile(
                leading: const Icon(Icons.key),
                title: const Text('Show recovery key'),
                subtitle: const Text('Needed to restore on a new device'),
                onTap: () => _showKey(context),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Recent results',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (runs.isEmpty) const Text('No backups yet.'),
              for (final r in runs.take(10))
                ListTile(
                  dense: true,
                  leading: Icon(
                    r.ok ? Icons.check_circle_outline : Icons.error_outline,
                    color: r.ok
                        ? Colors.green
                        : Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    accounts
                            .where((a) => a.id == r.accountId)
                            .map((a) => a.displayName)
                            .firstOrNull ??
                        'Removed account',
                  ),
                  subtitle: Text(
                    r.ok
                        ? formatAgo(r.at.toLocal(), DateTime.now())
                        : '${formatAgo(r.at.toLocal(), DateTime.now())} · ${r.error ?? 'failed'}',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showKey(BuildContext context) async {
    final key = await AppScope.servicesOf(context).keys.load();
    if (key == null || !context.mounted) return;
    final code = RecoveryKey.encode(key);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recovery key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Anyone with this key and access to your cloud can read your backups. Keep it private.',
            ),
            const SizedBox(height: 12),
            SelectableText(
              code,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: code)),
            child: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
