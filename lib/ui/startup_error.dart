import 'package:flutter/material.dart';

/// Shown when the app cannot open its database or the OS keystore. Secrets
/// are never stored anywhere else, so there is no unsafe fallback.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error});
  final Object error;

  static String hint(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('libsecret') ||
        text.contains('secret service') ||
        text.contains('org.freedesktop') ||
        text.contains('keyring')) {
      return 'CloudRelaef keeps your cloud sign-ins in the system keyring. '
          'On Linux, install and unlock a Secret Service provider such as '
          'gnome-keyring or KWallet, then start the app again.';
    }
    return 'The app could not open its local storage.';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    "CloudRelaef can't start",
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 12),
                  Text(hint(error), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(
                    '$error',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
