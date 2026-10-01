import 'package:flutter/material.dart';

import '../data/db/database.dart';
import 'app_scope.dart';
import 'util.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.services;
    return Scaffold(
      appBar: AppBar(title: const Text('Trash')),
      body: FutureBuilder<List<FileEntry>>(
        future: s.files.list(trashed: true),
        builder: (context, snap) {
          final files = snap.data;
          if (files == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (files.isEmpty) return const Center(child: Text('Trash is empty'));
          return ListView(
            children: [
              for (final f in files)
                ListTile(
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: Text(f.name),
                  subtitle: Text(formatBytes(f.size)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Restore',
                        icon: const Icon(Icons.restore_from_trash),
                        onPressed: () async {
                          await s.files.restore(f.id);
                          app.refresh();
                        },
                      ),
                      IconButton(
                        tooltip: 'Delete for good',
                        icon: const Icon(Icons.delete_forever_outlined),
                        onPressed: () async {
                          final ok = await confirm(
                            context,
                            title: 'Delete for good?',
                            message:
                                '"${f.name}" will be removed from the cloud. This cannot be undone.',
                            action: 'Delete',
                          );
                          if (!ok || !context.mounted) return;
                          await withProgress(
                            context,
                            'Deleting...',
                            () => s.files.purge(f.id),
                          );
                          app.refresh();
                        },
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
