import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../data/db/database.dart';
import '../providers/storage_provider.dart';
import '../services/accounts.dart';
import '../services/files.dart';
import '../services/folders.dart';
import '../services/placement.dart';

/// Names that file managers create on their own. Accepted and discarded so
/// the client is happy, but never stored in the user's cloud.
bool isJunkName(String name) =>
    name == '.DS_Store' ||
    name == 'Thumbs.db' ||
    name == 'desktop.ini' ||
    name.startsWith('._') ||
    name == '.localized';

class _Node {
  _Node.folder(this.folder) : file = null, name = folder!.name;
  _Node.file(this.file, this.name) : folder = null;
  final Folder? folder;
  final FileEntry? file;
  final String name;
  bool get isFolder => folder != null;
}

/// A snapshot of the virtual tree, built per request.
class _Tree {
  _Tree(List<Folder> folders, List<FileEntry> files) {
    final byParent = <int?, List<Folder>>{};
    for (final f in folders) {
      byParent.putIfAbsent(f.parentId, () => []).add(f);
    }
    final filesBy = <int?, List<FileEntry>>{};
    for (final f in files) {
      filesBy.putIfAbsent(f.folderId, () => []).add(f);
    }
    for (final parent in {...byParent.keys, ...filesBy.keys}) {
      final nodes = <_Node>[];
      final taken = <String>{};
      final subfolders = [...?byParent[parent]]
        ..sort((a, b) => a.id.compareTo(b.id));
      for (final f in subfolders) {
        nodes.add(_Node.folder(f));
        taken.add(f.name);
      }
      final inFolder = [...?filesBy[parent]]
        ..sort((a, b) => a.id.compareTo(b.id));
      for (final f in inFolder) {
        nodes.add(_Node.file(f, _unique(f.name, taken)));
      }
      _children[parent] = nodes;
    }
  }

  final Map<int?, List<_Node>> _children = {};

  /// Two files can share a name (they may live in different clouds), and a
  /// file may share a name with a folder: the later one gets "name (2).ext".
  static String _unique(String name, Set<String> taken) {
    var candidate = name;
    var n = 2;
    while (!taken.add(candidate)) {
      candidate =
          '${p.basenameWithoutExtension(name)} ($n)${p.extension(name)}';
      n++;
    }
    return candidate;
  }

  List<_Node> childrenOf(int? folderId) => _children[folderId] ?? const [];

  _Node? child(int? folderId, String name) {
    final kids = childrenOf(folderId);
    for (final k in kids) {
      if (k.name == name) return k;
    }
    final lower = name.toLowerCase();
    for (final k in kids) {
      if (k.name.toLowerCase() == lower) return k;
    }
    return null;
  }

  /// Folder id for a folder path; null segments list = root. Returns
  /// `(found, id)`.
  (bool, int?) folderAt(List<String> segments) {
    int? id;
    for (final s in segments) {
      final n = child(id, s);
      if (n == null || !n.isFolder) return (false, null);
      id = n.folder!.id;
    }
    return (true, id);
  }

  _Node? resolve(List<String> segments) {
    if (segments.isEmpty) return null;
    final (ok, parent) = folderAt(segments.sublist(0, segments.length - 1));
    if (!ok) return null;
    return child(parent, segments.last);
  }

  /// Every folder id below (and including) [id].
  List<int> subtreeFolders(int id) {
    final out = [id];
    for (var i = 0; i < out.length; i++) {
      for (final n in childrenOf(out[i])) {
        if (n.isFolder) out.add(n.folder!.id);
      }
    }
    return out;
  }
}

/// A WebDAV server for the pooled files, backed by the app's own services.
/// Binds to loopback only; every request needs the generated password.
class WebDavServer {
  WebDavServer({
    required this.files,
    required this.folders,
    required this.accounts,
    required this.password,
    required this.tempDir,
    this.username = 'cloudrelaef',
    this.port = 0,
    Random? rng,
  }) : _rng = rng ?? Random.secure();

  final FileService files;
  final FolderService folders;
  final AccountService accounts;
  final String username;
  final String password;
  final Directory tempDir;
  final int port;
  final Random _rng;

  HttpServer? _server;

  bool get running => _server != null;
  int get boundPort => _server!.port;

  Future<int> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    _server = server;
    server.listen(_handle);
    return server.port;
  }

  Future<void> stop() async {
    final s = _server;
    _server = null;
    await s?.close(force: true);
  }

  // ------------------------------------------------------------ plumbing

  static const _allow =
      'OPTIONS, PROPFIND, GET, HEAD, PUT, DELETE, MKCOL, MOVE, COPY, LOCK, UNLOCK';

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    try {
      if (!_hostAllowed(req)) {
        return await _finish(res, HttpStatus.forbidden, 'Forbidden host');
      }
      if (!_authorized(req)) {
        res.headers.set(
          'WWW-Authenticate',
          'Basic realm="CloudRelaef", charset="UTF-8"',
        );
        return await _finish(
          res,
          HttpStatus.unauthorized,
          'Authentication required',
        );
      }
      res.headers.set('DAV', '1, 2');
      res.headers.set('MS-Author-Via', 'DAV');
      final segments = _segments(req.uri);
      if (segments == null) {
        return await _finish(res, HttpStatus.badRequest, 'Bad path');
      }
      switch (req.method) {
        case 'OPTIONS':
          res.headers.set('Allow', _allow);
          return await _finish(res, HttpStatus.ok);
        case 'PROPFIND':
          return await _propfind(req, segments);
        case 'GET':
        case 'HEAD':
          return await _get(req, segments);
        case 'PUT':
          return await _put(req, segments);
        case 'DELETE':
          return await _delete(res, segments);
        case 'MKCOL':
          return await _mkcol(res, segments);
        case 'MOVE':
        case 'COPY':
          return await _moveCopy(req, segments, copy: req.method == 'COPY');
        case 'LOCK':
          return await _lock(res);
        case 'UNLOCK':
          return await _finish(res, HttpStatus.noContent);
        default:
          res.headers.set('Allow', _allow);
          return await _finish(res, HttpStatus.methodNotAllowed);
      }
    } catch (e) {
      await _finish(res, _statusFor(e), _messageFor(e));
    }
  }

  /// Blocks DNS-rebinding: browsers send the attacker's host name.
  bool _hostAllowed(HttpRequest req) {
    final host = req.headers.host?.toLowerCase();
    return host == 'localhost' || host == '127.0.0.1' || host == '::1';
  }

  bool _authorized(HttpRequest req) {
    final header = req.headers.value(HttpHeaders.authorizationHeader);
    if (header == null || !header.startsWith('Basic ')) return false;
    String decoded;
    try {
      decoded = utf8.decode(base64.decode(header.substring(6).trim()));
    } catch (_) {
      return false;
    }
    final i = decoded.indexOf(':');
    if (i < 0) return false;
    final user = decoded.substring(0, i);
    final pass = decoded.substring(i + 1);
    // Both compared, no early exit, so timing says nothing about either.
    final userOk = _constantTimeEquals(user, username);
    final passOk = _constantTimeEquals(pass, password);
    return userOk && passOk;
  }

  static bool _constantTimeEquals(String a, String b) {
    final x = utf8.encode(a);
    final y = utf8.encode(b);
    var diff = x.length ^ y.length;
    for (var i = 0; i < max(x.length, y.length); i++) {
      diff |= (i < x.length ? x[i] : 0) ^ (i < y.length ? y[i] : 0);
    }
    return diff == 0;
  }

  /// Decoded path segments, or null for something we refuse (e.g. an
  /// encoded slash inside a name).
  List<String>? _segments(Uri uri) {
    final out = <String>[];
    for (final s in uri.pathSegments) {
      if (s.isEmpty) continue;
      if (s.contains('/') || s.contains('\u0000') || s == '..' || s == '.') {
        return null;
      }
      out.add(s);
    }
    return out;
  }

  Future<void> _finish(HttpResponse res, int status, [String? body]) async {
    res.statusCode = status;
    if (body != null) {
      res.headers.contentType = ContentType.text;
      res.write(body);
    }
    await res.close();
  }

  int _statusFor(Object e) {
    if (e is NoCapacityError) return HttpStatus.insufficientStorage;
    if (e is FolderException || e is FileException) return HttpStatus.conflict;
    if (e is ReauthRequired) return HttpStatus.badGateway;
    if (e is ProviderError) return HttpStatus.badGateway;
    return HttpStatus.internalServerError;
  }

  /// Never echoes internals or anything token-like.
  String _messageFor(Object e) {
    if (e is NoCapacityError) {
      return 'No connected account has enough free space';
    }
    if (e is FolderException) return e.message;
    if (e is FileException) return e.message;
    if (e is ReauthRequired) {
      return 'A cloud account needs reconnecting in the app';
    }
    if (e is ProviderError) return 'The cloud provider refused the request';
    return 'Internal error';
  }

  Future<_Tree> _tree() async =>
      _Tree(await folders.list(), await files.list(limit: 1 << 30));

  // ------------------------------------------------------------ PROPFIND

  String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  String _href(List<String> segments, {required bool collection}) {
    if (segments.isEmpty) return '/';
    // Segments are percent-encoded; the leading slash is ours to add.
    final path = '/${Uri(pathSegments: segments).path}';
    return collection ? '$path/' : path;
  }

  String _entry(
    List<String> segments,
    _Node? node, {
    ({int available, int used})? quota,
  }) {
    final isCollection = node == null || node.isFolder;
    final sb = StringBuffer('<D:response><D:href>')
      ..write(_esc(_href(segments, collection: isCollection)))
      ..write('</D:href><D:propstat><D:prop>');
    final name = segments.isEmpty ? '' : segments.last;
    sb.write('<D:displayname>${_esc(name)}</D:displayname>');
    if (isCollection) {
      sb.write('<D:resourcetype><D:collection/></D:resourcetype>');
      if (quota != null) {
        sb.write(
          '<D:quota-available-bytes>${quota.available}</D:quota-available-bytes>'
          '<D:quota-used-bytes>${quota.used}</D:quota-used-bytes>',
        );
      }
    } else {
      final f = node.file!;
      sb.write('<D:resourcetype/>');
      sb.write('<D:getcontentlength>${f.size}</D:getcontentlength>');
      sb.write(
        '<D:getcontenttype>${_esc(f.mime.isEmpty ? 'application/octet-stream' : f.mime)}</D:getcontenttype>',
      );
      final modified = f.modifiedAt ?? f.indexedAt;
      sb.write(
        '<D:getlastmodified>${HttpDate.format(modified.toUtc())}</D:getlastmodified>',
      );
      sb.write(
        '<D:getetag>"${f.id}-${f.size}-${modified.millisecondsSinceEpoch}"</D:getetag>',
      );
    }
    sb.write(
      '</D:prop><D:status>HTTP/1.1 200 OK</D:status></D:propstat></D:response>',
    );
    return sb.toString();
  }

  Future<({int available, int used})> _quota() async {
    var used = 0;
    var total = 0;
    var unlimited = false;
    for (final a in await accounts.list()) {
      if (a.status != AccountStatus.active) continue;
      used += a.quotaUsed;
      if (a.quotaTotal == null) {
        unlimited = true;
      } else {
        total += a.quotaTotal!;
      }
    }
    final available = unlimited ? (1 << 50) : (total - used).clamp(0, total);
    return (available: available, used: used);
  }

  Future<void> _propfind(HttpRequest req, List<String> segments) async {
    await req.drain<void>(); // the request body only lists wanted props
    final tree = await _tree();
    final res = req.response;
    _Node? node;
    int? folderId;
    if (segments.isNotEmpty) {
      node = tree.resolve(segments);
      if (node == null || isJunkName(segments.last)) {
        return _finish(res, HttpStatus.notFound, 'Not found');
      }
      folderId = node.isFolder ? node.folder!.id : null;
    }
    final depth = req.headers.value('Depth') ?? '1';
    final parts = StringBuffer(
      '<?xml version="1.0" encoding="utf-8"?><D:multistatus xmlns:D="DAV:">',
    );
    final quota = segments.isEmpty ? await _quota() : null;
    parts.write(_entry(segments, node, quota: quota));
    final isCollection = node == null || node.isFolder;
    if (isCollection && depth != '0') {
      for (final child in tree.childrenOf(folderId)) {
        parts.write(_entry([...segments, child.name], child));
      }
    }
    parts.write('</D:multistatus>');
    res.statusCode = 207;
    res.headers.contentType = ContentType(
      'application',
      'xml',
      charset: 'utf-8',
    );
    res.write(parts.toString());
    await res.close();
  }

  // ----------------------------------------------------------- GET / HEAD

  Future<void> _get(HttpRequest req, List<String> segments) async {
    final res = req.response;
    final tree = await _tree();
    final node = segments.isEmpty ? null : tree.resolve(segments);
    if (node == null && segments.isNotEmpty ||
        (segments.isNotEmpty && isJunkName(segments.last))) {
      return _finish(res, HttpStatus.notFound, 'Not found');
    }
    if (node == null || node.isFolder) {
      return _finish(
        res,
        HttpStatus.methodNotAllowed,
        'This is a folder; use PROPFIND',
      );
    }
    final f = node.file!;
    res.headers.contentType = ContentType.parse(
      f.mime.contains('/') ? f.mime : 'application/octet-stream',
    );
    res.headers.set(HttpHeaders.acceptRangesHeader, 'none');
    res.headers.set(
      HttpHeaders.lastModifiedHeader,
      HttpDate.format((f.modifiedAt ?? f.indexedAt).toUtc()),
    );
    res.contentLength = f.size;
    if (req.method == 'HEAD') return res.close();
    // Open the cloud stream before committing to 200, so an error is a 5xx.
    final stream = await files.download(f.id);
    await res.addStream(stream.map((c) => c));
    await res.close();
  }

  // ------------------------------------------------------------------ PUT

  Future<void> _put(HttpRequest req, List<String> segments) async {
    final res = req.response;
    if (segments.isEmpty) {
      await req.drain<void>();
      return _finish(
        res,
        HttpStatus.methodNotAllowed,
        'Cannot write to the root',
      );
    }
    final name = segments.last;
    if (isJunkName(name)) {
      await req.drain<void>();
      return _finish(res, HttpStatus.created);
    }
    final tree = await _tree();
    final (ok, parent) = tree.folderAt(
      segments.sublist(0, segments.length - 1),
    );
    if (!ok) {
      await req.drain<void>();
      return _finish(res, HttpStatus.conflict, 'Parent folder does not exist');
    }
    final existing = tree.child(parent, name);
    if (existing != null && existing.isFolder) {
      await req.drain<void>();
      return _finish(
        res,
        HttpStatus.methodNotAllowed,
        'A folder has that name',
      );
    }

    // Uploads need the size up front; clients that stream (chunked) are
    // buffered to a temp file first.
    File? temp;
    Stream<List<int>> data = req;
    var size = req.contentLength;
    try {
      if (size < 0) {
        await tempDir.create(recursive: true);
        temp = File(p.join(tempDir.path, 'put-${_rng.nextInt(1 << 32)}'));
        final sink = temp.openWrite();
        await sink.addStream(req);
        await sink.close();
        size = await temp.length();
        data = temp.openRead();
      }
      final entry = await files.upload(
        name: name,
        size: size,
        mime: lookupMimeType(name) ?? 'application/octet-stream',
        data: data,
        folderId: parent,
      );
      if (existing != null) {
        await _replaceDone(existing.file!, entry, name);
      }
    } finally {
      if (temp != null && await temp.exists()) await temp.delete();
    }
    return _finish(
      res,
      existing == null ? HttpStatus.created : HttpStatus.noContent,
    );
  }

  /// Overwrite semantics: the old copy is deleted at the cloud (after the new
  /// one is safely uploaded), and the new one gets the wanted name back if
  /// the provider renamed it to avoid the clash.
  Future<void> _replaceDone(
    FileEntry old,
    FileEntry created,
    String wantedName,
  ) async {
    await files.trash(old.id);
    try {
      await files.purge(old.id);
    } on ProviderError {
      return; // stays in the trash; the new file is in place
    }
    if (created.name != wantedName) {
      try {
        await files.rename(created.id, wantedName);
      } on ProviderError {
        // Keep the provider's name rather than failing a finished upload.
      }
    }
  }

  // --------------------------------------------------------------- DELETE

  Future<void> _delete(HttpResponse res, List<String> segments) async {
    if (segments.isEmpty) {
      return _finish(res, HttpStatus.forbidden, 'Cannot delete the root');
    }
    if (isJunkName(segments.last)) return _finish(res, HttpStatus.noContent);
    final tree = await _tree();
    final node = tree.resolve(segments);
    if (node == null) return _finish(res, HttpStatus.notFound, 'Not found');
    await _remove(tree, node);
    return _finish(res, HttpStatus.noContent);
  }

  /// Files go to the trash (recoverable); folders are removed with their
  /// contents trashed. Trashed files leave the folder so it can go.
  Future<void> _remove(_Tree tree, _Node node) async {
    if (!node.isFolder) {
      await files.trash(node.file!.id);
      return;
    }
    final ids = tree.subtreeFolders(node.folder!.id);
    for (final id in ids) {
      for (final n in tree.childrenOf(id)) {
        if (!n.isFolder) {
          await files.trash(n.file!.id);
          await files.moveToFolder(n.file!.id, null);
        }
      }
    }
    for (final id in ids.reversed) {
      await folders.delete(id);
    }
  }

  // ---------------------------------------------------------------- MKCOL

  Future<void> _mkcol(HttpResponse res, List<String> segments) async {
    if (segments.isEmpty) return _finish(res, HttpStatus.methodNotAllowed);
    final tree = await _tree();
    final (ok, parent) = tree.folderAt(
      segments.sublist(0, segments.length - 1),
    );
    if (!ok) {
      return _finish(res, HttpStatus.conflict, 'Parent folder does not exist');
    }
    if (tree.child(parent, segments.last) != null) {
      return _finish(res, HttpStatus.methodNotAllowed, 'Already exists');
    }
    await folders.create(segments.last, parentId: parent);
    return _finish(res, HttpStatus.created);
  }

  // ---------------------------------------------------------- MOVE / COPY

  Future<void> _moveCopy(
    HttpRequest req,
    List<String> segments, {
    required bool copy,
  }) async {
    final res = req.response;
    await req.drain<void>();
    final destHeader = req.headers.value('Destination');
    if (destHeader == null || segments.isEmpty) {
      return _finish(res, HttpStatus.badRequest, 'Missing destination');
    }
    final dest = _segments(Uri.parse(destHeader));
    if (dest == null || dest.isEmpty) {
      return _finish(res, HttpStatus.badRequest, 'Bad destination');
    }
    if (isJunkName(segments.last) || isJunkName(dest.last)) {
      return _finish(res, HttpStatus.created);
    }
    final overwrite =
        (req.headers.value('Overwrite') ?? 'T').toUpperCase() != 'F';

    var tree = await _tree();
    final src = tree.resolve(segments);
    if (src == null) return _finish(res, HttpStatus.notFound, 'Not found');
    final (parentOk, destParent) = tree.folderAt(
      dest.sublist(0, dest.length - 1),
    );
    if (!parentOk) {
      return _finish(
        res,
        HttpStatus.conflict,
        'Destination folder does not exist',
      );
    }
    final destName = dest.last;
    final existing = tree.child(destParent, destName);
    if (existing != null &&
        identical(existing.file ?? existing.folder, src.file ?? src.folder)) {
      return _finish(
        res,
        HttpStatus.forbidden,
        'Source and destination are the same',
      );
    }
    if (existing != null && !overwrite) {
      return _finish(res, HttpStatus.preconditionFailed, 'Destination exists');
    }
    if (copy && src.isFolder) {
      return _finish(
        res,
        HttpStatus.notImplemented,
        'Copying folders is not supported',
      );
    }

    if (copy) {
      final f = src.file!;
      final entry = await files.upload(
        name: destName,
        size: f.size,
        mime: f.mime.isEmpty
            ? (lookupMimeType(destName) ?? 'application/octet-stream')
            : f.mime,
        data: await files.download(f.id),
        folderId: destParent,
      );
      if (existing != null && !existing.isFolder) {
        await _replaceDone(existing.file!, entry, destName);
      }
      return _finish(
        res,
        existing == null ? HttpStatus.created : HttpStatus.noContent,
      );
    }

    if (existing != null) {
      if (existing.isFolder != src.isFolder) {
        return _finish(
          res,
          HttpStatus.preconditionFailed,
          'Cannot replace a ${existing.isFolder ? 'folder with a file' : 'file with a folder'}',
        );
      }
      await _removeForReplace(tree, existing);
      tree = await _tree();
    }

    if (src.isFolder) {
      final id = src.folder!.id;
      if (src.folder!.name != destName) await folders.rename(id, destName);
      if (src.folder!.parentId != destParent) {
        await folders.move(id, destParent);
      }
    } else {
      final f = src.file!;
      if (f.name != destName) await files.rename(f.id, destName);
      if (f.folderId != destParent) await files.moveToFolder(f.id, destParent);
    }
    return _finish(
      res,
      existing == null ? HttpStatus.created : HttpStatus.noContent,
    );
  }

  /// Replacing a destination deletes it at the cloud (files) or removes the
  /// folder tree (trashing its files).
  Future<void> _removeForReplace(_Tree tree, _Node existing) async {
    if (existing.isFolder) return _remove(tree, existing);
    await files.trash(existing.file!.id);
    try {
      await files.purge(existing.file!.id);
    } on ProviderError {
      // Left in the trash; the move still goes ahead.
    }
  }

  // ----------------------------------------------------------------- LOCK

  /// Finder and Office refuse to write unless LOCK works. Nothing is really
  /// locked; this is a single-user server on the device.
  Future<void> _lock(HttpResponse res) async {
    final token =
        'opaquelocktoken:${List.generate(16, (_) => _rng.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
    res.statusCode = HttpStatus.ok;
    res.headers.set('Lock-Token', '<$token>');
    res.headers.contentType = ContentType(
      'application',
      'xml',
      charset: 'utf-8',
    );
    res.write(
      '<?xml version="1.0" encoding="utf-8"?><D:prop xmlns:D="DAV:"><D:lockdiscovery>'
      '<D:activelock><D:locktype><D:write/></D:locktype><D:lockscope><D:exclusive/></D:lockscope>'
      '<D:depth>0</D:depth><D:timeout>Second-3600</D:timeout>'
      '<D:locktoken><D:href>$token</D:href></D:locktoken></D:activelock></D:lockdiscovery></D:prop>',
    );
    await res.close();
  }
}
