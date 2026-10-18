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

  /// The file when it is already on this phone, or null. Unlike [fileFor]
  /// this never downloads, so it is safe to ask while music is playing.
  Future<File?> existing(String name) async {
    if (!_validName.hasMatch(name)) return null;
    try {
      final file = File(p.join((await _folder()).path, name));
      return await file.exists() ? file : null;
    } catch (error) {
      debugPrint('Media $name not looked up: $error');
      return null;
    }
  }

  /// Makes sure every one of [names] is on this phone. With [tidy], also
  /// removes the files the content no longer mentions, so the folder does
  /// not grow for ever. Only the server's own word is a reason to tidy, so
  /// callers pass [tidy] only for content that just came from it. Never
  /// throws.
  Future<void> sync(Set<String> names, {bool tidy = false}) async {
    for (final name in names) {
      await fileFor(name);
    }
    if (!tidy) return;
    try {
      final folder = await _folder();
      await for (final entry in folder.list()) {
        if (entry is! File) continue;
        final name = p.basename(entry.path);
        if (names.contains(name) || _inFlight.containsKey(name)) continue;
        await entry.delete();
      }
    } catch (error) {
      debugPrint('Media folder not tidied: $error');
    }
  }

  /// How many files are kept on this phone and how much room they take.
  /// Never throws.
  Future<({int files, int bytes})> usage() async {
    var files = 0;
    var bytes = 0;
    try {
      final folder = await _folder();
      await for (final entry in folder.list()) {
        if (entry is! File || entry.path.endsWith('.part')) continue;
        files++;
        bytes += await entry.length();
      }
    } catch (error) {
      debugPrint('Media folder not read: $error');
    }
    return (files: files, bytes: bytes);
  }

  /// Deletes every downloaded file. Photos still in the content download
  /// again the next time they are shown. Never throws.
  Future<void> clear() async {
    try {
      final folder = await _folder();
      await for (final entry in folder.list()) {
        if (entry is File) await entry.delete();
      }
    } catch (error) {
      debugPrint('Media folder not cleared: $error');
    }
  }
}
