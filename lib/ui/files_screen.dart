import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../data/db/database.dart';
import '../services/accounts.dart';
import '../services/files.dart';
import '../services/folders.dart';
import '../services/placement.dart';
import 'app_scope.dart';
import 'trash_screen.dart';
import 'util.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  int? _folderId; // null = top level
  String _query = '';
  bool _searching = false;

  Future<({List<Folder> folders, List<FileEntry> files, List<Folder> all})>
  _load() async {
    final s = AppScope.servicesOf(context);
    final all = await s.folders.list();
    final searching = _query.trim().isNotEmpty;
    final files = await s.files.list(
      query: searching ? _query : null,
      folderId: searching ? null : _folderId,
      topLevelOnly: !searching && _folderId == null,
    );
    final folders = searching
        ? <Folder>[]
        : (all.where((f) => f.parentId == _folderId).toList()..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          ));
    return (folders: folders, files: files, all: all);
  }

  List<Folder> _trail(List<Folder> all) {
    final trail = <Folder>[];
    var id = _folderId;
    while (id != null) {
      final f = all.firstWhere((x) => x.id == id);
      trail.insert(0, f);
      id = f.parentId;
    }
    return trail;
  }

  Future<void> _upload() async {
    final app = AppScope.of(context);
    final picked = await FilePicker.pickFiles();
    if (picked.isEmpty || !mounted) return;
    var done = 0;
    for (final f in picked) {
      final size = await f.length();
      if (size == null) {
        if (mounted) toast(context, 'Could not read ${f.name}');
        continue;
      }
      if (!mounted) return;
      final entry = await withProgress(
        context,
        'Uploading ${f.name} (${done + 1}/${picked.length})...',
        () => app.services.files.upload(
          name: f.name,
          size: size,
          mime: lookupMimeType(f.name) ?? 'application/octet-stream',
          data: f.readAsByteStream(),
          folderId: _folderId,
        ),
      );
      if (entry != null) done++;
    }
    app.refresh();
    if (mounted && done > 0) toast(context, 'Uploaded $done file(s)');
  }

  Future<void> _newFolder() async {
    final app = AppScope.of(context);
    final name = await promptText(
      context,
      title: 'New folder',
      action: 'Create',
    );
    if (name == null) return;
    try {
      await app.services.folders.create(name, parentId: _folderId);
      app.refresh();
    } on FolderException catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  Future<void> _download(FileEntry f) async {
    final s = AppScope.servicesOf(context);
    final path = await withProgress(context, 'Downloading ${f.name}...', () async {
      var target = File(p.join(s.downloadsDir.path, f.name));
      var n = 1;
      while (await target.exists()) {
        target = File(
          p.join(
            s.downloadsDir.path,
            '${p.basenameWithoutExtension(f.name)} ($n)${p.extension(f.name)}',
          ),
        );
        n++;
      }
      final sink = target.openWrite();
      try {
        await sink.addStream(await s.files.download(f.id));
      } catch (_) {
        await sink.close();
        if (await target.exists()) await target.delete();
        rethrow;
      }
      await sink.close();
      return target.path;
    });
    if (path != null && mounted) toast(context, 'Saved to $path');
  }

  Future<void> _fileAction(
    FileEntry f,
    String action,
    List<Folder> allFolders,
  ) async {
    final app = AppScope.of(context);
    final s = app.services;
    switch (action) {
      case 'download':
        await _download(f);
      case 'rename':
        final name = await promptText(
          context,
          title: 'Rename',
          initial: f.name,
          action: 'Rename',
        );
        if (name == null || name.trim().isEmpty || name == f.name || !mounted) {
          return;
        }
        await withProgress(
          context,
          'Renaming...',
          () => s.files.rename(f.id, name.trim()),
        );
      case 'move':
        final target = await _pickFolder(allFolders);
        if (target == null || !mounted) return;
        await s.files.moveToFolder(f.id, target.id == -1 ? null : target.id);
      case 'transfer':
        final accounts = (await s.accounts.list())
            .where(
              (a) => a.id != f.accountId && a.status == AccountStatus.active,
            )
            .toList();
        if (!mounted) return;
        if (accounts.isEmpty) {
          toast(context, 'Connect another account first');
          return;
        }
        final chosen = await showDialog<LinkedAccount>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('Move to which account?'),
            children: [
              for (final a in accounts)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, a),
                  child: Text(a.displayName),
                ),
            ],
          ),
        );
        if (chosen == null || !mounted) return;
        final res = await withProgress<TransferResult>(
          context,
          'Moving ${f.name}...',
          () => s.files.transfer(f.id, chosen.id),
        );
        if (res != null && !res.sourceDeleted && mounted) {
          toast(
            context,
            'Copied, but the original could not be deleted. Delete it in the old cloud.',
          );
        }
      case 'trash':
        await s.files.trash(f.id);
    }
    app.refresh();
  }

  Future<Folder?> _pickFolder(List<Folder> all) => showDialog<Folder>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Move to folder'),
      children: [
        SimpleDialogOption(
          onPressed: () =>
              Navigator.pop(ctx, const Folder(id: -1, name: 'Top level')),
          child: const Text('Top level'),
        ),
        for (final f in all)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, f),
            child: Text(_path(all, f)),
          ),
      ],
    ),
  );

  String _path(List<Folder> all, Folder f) {
    final parts = <String>[f.name];
    var parent = f.parentId;
    while (parent != null) {
      final pf = all.firstWhere((x) => x.id == parent);
      parts.insert(0, pf.name);
      parent = pf.parentId;
    }
    return parts.join(' / ');
  }

  Future<void> _folderAction(Folder f, String action) async {
    final app = AppScope.of(context);
    try {
      if (action == 'rename') {
        final name = await promptText(
          context,
          title: 'Rename folder',
          initial: f.name,
          action: 'Rename',
        );
        if (name == null) return;
        await app.services.folders.rename(f.id, name);
      } else {
        await app.services.folders.delete(f.id);
      }
      app.refresh();
    } on FolderException catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppScope.of(context); // rebuild on data changes
    return FutureBuilder(
      future: _load(),
      builder: (context, snap) {
        final data = snap.data;
        final trail = data == null ? <Folder>[] : _trail(data.all);
        return Scaffold(
          appBar: AppBar(
            leading: _folderId != null && !_searching
                ? BackButton(
                    onPressed: () => setState(
                      () => _folderId = trail.length > 1
                          ? trail[trail.length - 2].id
                          : null,
                    ),
                  )
                : null,
            title: _searching
                ? TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search all files',
                      border: InputBorder.none,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  )
                : Text(
                    trail.isEmpty
                        ? 'Files'
                        : trail.map((f) => f.name).join(' / '),
                  ),
            actions: [
              IconButton(
                tooltip: 'Search',
                icon: Icon(_searching ? Icons.close : Icons.search),
                onPressed: () => setState(() {
                  _searching = !_searching;
                  if (!_searching) _query = '';
                }),
              ),
              IconButton(
                tooltip: 'New folder',
                icon: const Icon(Icons.create_new_folder_outlined),
                onPressed: _newFolder,
              ),
              IconButton(
                tooltip: 'Trash',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const TrashScreen()),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _upload,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload'),
          ),
          body: data == null
              ? const Center(child: CircularProgressIndicator())
              : (data.folders.isEmpty && data.files.isEmpty)
              ? Center(
                  child: Text(
                    _query.isNotEmpty ? 'Nothing found' : 'No files here yet',
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 88),
                  children: [
                    for (final f in data.folders)
                      ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: Text(f.name),
                        onTap: () => setState(() => _folderId = f.id),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) => _folderAction(f, v),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'rename',
                              child: Text('Rename'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete (if empty)'),
                            ),
                          ],
                        ),
                      ),
                    for (final f in data.files)
                      ListTile(
                        leading: const Icon(Icons.insert_drive_file_outlined),
                        title: Text(f.name, overflow: TextOverflow.ellipsis),
                        subtitle: Text(formatBytes(f.size)),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) => _fileAction(f, v, data.all),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'download',
                              child: Text('Download'),
                            ),
                            PopupMenuItem(
                              value: 'rename',
                              child: Text('Rename'),
                            ),
                            PopupMenuItem(
                              value: 'move',
                              child: Text('Move to folder'),
                            ),
                            PopupMenuItem(
                              value: 'transfer',
                              child: Text('Move to another account'),
                            ),
                            PopupMenuItem(
                              value: 'trash',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

// Used by the "no capacity" message path in uploads.
String uploadErrorText(Object e) => e is NoCapacityError
    ? 'No connected account has enough free space for this file.'
    : errorText(e);
