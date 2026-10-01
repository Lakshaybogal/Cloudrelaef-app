import 'package:flutter/material.dart';

import '../ui/app_scope.dart';
import '../ui/home_shell.dart';
import '../ui/setup_screen.dart';

class CloudRelaefApp extends StatelessWidget {
  const CloudRelaefApp({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: MaterialApp(
        title: 'CloudRelaef',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        home: const _Gate(),
      ),
    );
  }
}

/// First run (no backup key yet) shows setup; otherwise the app.
class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final hasKey = AppScope.of(context).hasKey;
    if (hasKey == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return hasKey ? const HomeShell() : const SetupScreen();
  }
}
