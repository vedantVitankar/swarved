import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The last content the server sent, as text, with its tag.
class CachedContent {
  const CachedContent({required this.body, required this.etag});
  final String body;
  final String etag;
}

/// Keeps the last content on this phone, so the app opens with his notes
/// straight away and without a connection. Tests stand in for it.
abstract interface class ContentCache {
  /// The copy on file, or null when there is none or it cannot be read.
  Future<CachedContent?> read();

  Future<void> write(CachedContent content);
}

typedef ContentCacheDirectory = Future<Directory> Function();

/// The copy as one JSON file. A save goes to a temporary file first and is
/// then renamed over the real one, so a crash half way never leaves half a
/// file.
class FileContentCache implements ContentCache {
  FileContentCache({ContentCacheDirectory? directory})
      : _directory = directory ?? getApplicationSupportDirectory;

  static const fileName = 'content_cache_v1.json';

  final ContentCacheDirectory _directory;

  Future<File> _file([String suffix = '']) async {
    final directory = await _directory();
    return File(p.join(directory.path, '$fileName$suffix'));
  }

  @override
  Future<CachedContent?> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return null;
      final body = decoded['body'];
      final etag = decoded['etag'];
      if (body is! String || etag is! String) return null;
      return CachedContent(body: body, etag: etag);
    } catch (error) {
      // A copy that cannot be read is as good as none: the server has the
      // real one.
      debugPrint('Content copy not read: $error');
      return null;
    }
  }

  @override
  Future<void> write(CachedContent content) async {
    final file = await _file();
    final temporary = await _file('.tmp');
    await temporary.writeAsString(
      jsonEncode({'etag': content.etag, 'body': content.body}),
      flush: true,
    );
    await temporary.rename(file.path);
  }
}
