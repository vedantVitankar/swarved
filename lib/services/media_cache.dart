import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'secure_token_store.dart';
import 'server_config.dart';

typedef MediaDirectory = Future<Directory> Function();

/// The photos and recordings he uploads. Each is downloaded from the server
/// once and kept on this phone, so it shows at once next time and without a
/// connection.
class MediaCache {
  MediaCache({
    required ServerConfig config,
    required TokenStore tokenStore,
    http.Client? client,
    MediaDirectory? directory,
  })  : _config = config,
        _tokenStore = tokenStore,
        _client = client ?? http.Client(),
        _directory = directory ?? getApplicationSupportDirectory;

  /// What the server names a file: sixteen hex digits and an extension. The
  /// name goes into a path and a web address, so nothing else is accepted.
  static final _validName =
      RegExp(r'^[a-f0-9]{16}\.(jpg|png|webp|mp3|m4a|ogg|wav)$');

  static const _timeout = Duration(seconds: 30);

  final ServerConfig _config;
  final TokenStore _tokenStore;
  final http.Client _client;
  final MediaDirectory _directory;

  /// Downloads in progress, so two screens asking for one file share a
  /// single download.
  final Map<String, Future<File?>> _inFlight = {};

  Future<Directory> _folder() async {
    final base = await _directory();
    final folder = Directory(p.join(base.path, 'media'));
    if (!await folder.exists()) await folder.create(recursive: true);
    return folder;
  }

  /// The file on this phone, downloaded first if it is not there yet. Null
  /// when it cannot be had (a name that is not the server's, no token, no
  /// connection, or the server does not have it). Never throws.
  Future<File?> fileFor(String name) {
    if (!_validName.hasMatch(name)) return Future.value(null);
    return _inFlight.putIfAbsent(
      name,
      () => _fetch(name).whenComplete(() => _inFlight.remove(name)),
    );
  }

  Future<File?> _fetch(String name) async {
    try {
      final folder = await _folder();
      final file = File(p.join(folder.path, name));
      if (await file.exists()) return file;

      final token = await _tokenStore.readToken();
      if (token == null || token.trim().isEmpty) return null;

      final response = await _client.get(
        _config.mediaUri(name),
        headers: {'X-Token': token},
      ).timeout(_timeout);
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return null;
      }

      // Written under another name and renamed, so a file that exists is
      // always a whole one.
      final partial = File('${file.path}.part');
      await partial.writeAsBytes(response.bodyBytes, flush: true);
      await partial.rename(file.path);
      return file;
    } catch (error) {
      debugPrint('Media $name not fetched: $error');
      return null;
    }
  }

  /// Makes sure every one of [names] is on this phone, then removes the
  /// files that are no longer used, so the folder never grows for ever.
  /// Never throws.
  Future<void> sync(Set<String> names) async {
    for (final name in names) {
      await fileFor(name);
    }
    try {
      final folder = await _folder();
      await for (final entry in folder.list()) {
        if (entry is! File) continue;
        if (names.contains(p.basename(entry.path))) continue;
        await entry.delete();
      }
    } catch (error) {
      debugPrint('Media folder not tidied: $error');
    }
  }
}
