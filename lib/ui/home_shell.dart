import 'dart:async';

import 'package:flutter/material.dart';

import 'accounts_screen.dart';
import 'app_scope.dart';
import 'backup_screen.dart';
import 'dashboard_screen.dart';
import 'files_screen.dart';

/// Navigation plus the background chores that run while the app is open:
/// sync on start and the interval backup.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _chores());
    _timer = Timer.periodic(const Duration(minutes: 15), (_) => _chores());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _chores() async {
    if (!mounted) return;
    final app = AppScope.of(context);
    try {
      await app.services.sync.syncAll();
      await app.services.backup.runIfDue();
    } catch (_) {
      // Chores are best effort; the Backup screen shows real failures.
    }
    if (mounted) app.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardScreen(onOpenAccounts: () => setState(() => _index = 2)),
      const FilesScreen(),
      const AccountsScreen(),
      const BackupScreen(),
    ];
    const destinations = [
      (Icons.dashboard_outlined, Icons.dashboard, 'Pool'),
      (Icons.folder_outlined, Icons.folder, 'Files'),
      (Icons.cloud_outlined, Icons.cloud, 'Accounts'),
      (Icons.backup_outlined, Icons.backup, 'Backup'),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final body = IndexedStack(index: _index, children: pages);
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.$1),
                    selectedIcon: Icon(d.$2),
                    label: Text(d.$3),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.$1),
              selectedIcon: Icon(d.$2),
              label: d.$3,
            ),
        ],
      ),
    );
  }
}
