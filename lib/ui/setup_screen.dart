import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../backup/crypto.dart';
import 'app_scope.dart';
import 'restore_screen.dart';

/// First run: create the backup key, make the user save it, or restore.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  String? _code;
  bool _saved = false;

  /// Not stored until the user confirms they saved it (see [_finish]).
  void _create() =>
      setState(() => _code = RecoveryKey.encode(RecoveryKey.generate()));

  Future<void> _finish() async {
    final app = AppScope.of(context);
    await app.services.keys.store(RecoveryKey.decode(_code!));
    await app.reloadKeyState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                Icon(
                  Icons.cloud_sync_outlined,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'CloudRelaef',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Pool your free cloud storage. No account, no server: everything '
                  'runs on this device.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),
                if (_code == null) ...[
                  FilledButton.icon(
                    icon: const Icon(Icons.rocket_launch_outlined),
                    label: const Text('Get started'),
                    onPressed: _create,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.restore),
                    label: const Text('I already use CloudRelaef: restore'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RestoreScreen()),
                    ),
                  ),
                ] else ...[
                  Text('Your recovery key', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'Your index is backed up to all your clouds, encrypted with this key. '
                    'If you lose this device you need it to get everything back. '
                    'We cannot recover it for you.',
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        _code!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: 'monospace',
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                      onPressed: () =>
                          Clipboard.setData(ClipboardData(text: _code!)),
                    ),
                  ),
                  CheckboxListTile(
                    value: _saved,
                    onChanged: (v) => setState(() => _saved = v ?? false),
                    title: const Text(
                      'I saved it somewhere safe (password manager, paper)',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _saved ? _finish : null,
                    child: const Text('Continue'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
