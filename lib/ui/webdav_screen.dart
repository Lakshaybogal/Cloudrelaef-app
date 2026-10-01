import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../webdav/webdav_manager.dart';
import 'app_scope.dart';
import 'util.dart';

/// Turns the WebDAV drive on or off and shows how to mount it.
class WebDavScreen extends StatefulWidget {
  const WebDavScreen({super.key});

  @override
  State<WebDavScreen> createState() => _WebDavScreenState();
}

class _WebDavScreenState extends State<WebDavScreen> {
  bool _reveal = false;

  Future<void> _toggle(WebDavManager m, bool on) async {
    try {
      if (on) {
        await m.start();
      } else {
        await m.stop();
      }
    } on StateError catch (e) {
      if (mounted) toast(context, e.message);
    }
    if (mounted) AppScope.of(context).refresh();
  }

  Future<void> _changePort(WebDavManager m) async {
    final current = await m.port();
    if (!mounted) return;
    final text = await promptText(
      context,
      title: 'Port',
      initial: '$current',
      hint: '1024 - 65535',
      action: 'Save',
    );
    final port = int.tryParse(text ?? '');
    if (port == null || !mounted) return;
    try {
      await m.setPort(port);
    } on ArgumentError catch (e) {
      if (mounted) toast(context, '${e.message}');
    } on StateError catch (e) {
      if (mounted) toast(context, e.message);
    }
    if (mounted) AppScope.of(context).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final m = app.services.webdav;
    return Scaffold(
      appBar: AppBar(title: const Text('Drive (WebDAV)')),
      body: FutureBuilder(
        future: Future.wait([m.isEnabled(), m.password(), m.port()]),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final enabled = snap.data![0] as bool;
          final password = snap.data![1] as String;
          final port = snap.data![2] as int;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Mount your pooled storage as a network drive in Finder, Explorer, '
                'or any WebDAV app on this device. Only programs on this device '
                'can connect, and they need the password below.',
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Turn on'),
                subtitle: Text(
                  m.running
                      ? 'Running'
                      : enabled
                      ? 'On, but not running (is the port in use?)'
                      : 'Off',
                ),
                value: m.running,
                onChanged: (v) => _toggle(m, v),
              ),
              const Divider(),
              ListTile(
                title: const Text('Address'),
                subtitle: SelectableText('http://127.0.0.1:$port/'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Copy',
                      icon: const Icon(Icons.copy),
                      onPressed: () => Clipboard.setData(
                        ClipboardData(text: 'http://127.0.0.1:$port/'),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Change port',
                      icon: const Icon(Icons.edit),
                      onPressed: () => _changePort(m),
                    ),
                  ],
                ),
              ),
              const ListTile(
                title: Text('Username'),
                subtitle: SelectableText(WebDavManager.username),
              ),
              ListTile(
                title: const Text('Password'),
                subtitle: SelectableText(_reveal ? password : '•' * 24),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: _reveal ? 'Hide' : 'Show',
                      icon: Icon(
                        _reveal ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _reveal = !_reveal),
                    ),
                    IconButton(
                      tooltip: 'Copy',
                      icon: const Icon(Icons.copy),
                      onPressed: () =>
                          Clipboard.setData(ClipboardData(text: password)),
                    ),
                    IconButton(
                      tooltip: 'New password',
                      icon: const Icon(Icons.refresh),
                      onPressed: () async {
                        final ok = await confirm(
                          context,
                          title: 'Generate a new password?',
                          message: 'Anything already connected will have to sign in again.',
                          action: 'Generate',
                        );
                        if (!ok) return;
                        await m.regeneratePassword();
                        if (context.mounted) app.refresh();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              Text(
                'How to connect',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'macOS: Finder -> Go -> Connect to Server.\n'
                'Windows: Explorer -> This PC -> Map network drive (Windows only '
                'connects to a plain-HTTP address if you enable it in the registry; '
                'rclone or WinSCP are easier).\n'
                'Linux: Files -> Other Locations -> "dav://127.0.0.1:$port/", or rclone.\n'
                'Anything else: any WebDAV client with the address above.\n\n'
                'Deleting a file from the drive moves it to the app\'s Trash. '
                'Overwriting a file replaces it for good.',
              ),
            ],
          );
        },
      ),
    );
  }
}
