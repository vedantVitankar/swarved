import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/playlist.dart';

/// Where the playlists are kept between runs. The service only needs this
/// much, so tests can stand in for it.
abstract interface class PlaylistStore {
  /// Every playlist on file, deleted ones included. Empty when there is no
  /// file yet. Throws when the file is there but cannot be read at all, so
  /// the caller never mistakes "could not read" for "nothing there".
  Future<List<Playlist>> read();

  Future<void> write(List<Playlist> playlists);
}

typedef PlaylistDirectory = Future<Directory> Function();

/// The playlists as one JSON file on this device.
///
/// Losing playlists is the worst thing this can do, so:
/// - A save goes to a temporary file first and is then renamed over the real
///   one, so a crash half way never leaves half a file.
/// - The version before each save is kept as a ".prev" copy.
/// - A file that cannot be understood is moved aside, never deleted, and the
///   ".prev" copy is tried instead.
class FilePlaylistStore implements PlaylistStore {
  FilePlaylistStore({PlaylistDirectory? directory})
      : _directory = directory ?? getApplicationSupportDirectory;

  static const String fileName = 'playlists_v1.json';
  static const int version = 1;

  final PlaylistDirectory _directory;

  Future<File> _file([String suffix = '']) async {
    final directory = await _directory();
    return File(p.join(directory.path, '$fileName$suffix'));
  }

  @override
  Future<List<Playlist>> read() async {
    final main = await _file();
    if (!await main.exists()) {
      // Nothing yet, or only the copy from before a crash.
      return _readPrevious();
    }

    try {
      return _parse(await main.readAsString());
    } on FormatException catch (error) {
      debugPrint('Playlist file is damaged: ${error.message}');
      await _setAside(main);
      return _readPrevious();
    }
  }

  Future<List<Playlist>> _readPrevious() async {
    final previous = await _file('.prev');
    if (!await previous.exists()) return const [];
    try {
      return _parse(await previous.readAsString());
    } on FormatException catch (error) {
      debugPrint('Playlist copy is damaged too: ${error.message}');
      await _setAside(previous);
      return const [];
    }
  }

  /// Keeps a damaged file under a new name so nothing is ever thrown away.
  Future<void> _setAside(File file) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    try {
      await file.rename('${file.path}.damaged-$stamp');
    } on FileSystemException catch (error) {
      debugPrint('Could not set the damaged file aside: $error');
    }
  }

  static List<Playlist> _parse(String text) {
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      throw const FormatException('playlist file is not an object');
    }
    final raw = decoded['playlists'];
    if (raw is! List) {
      throw const FormatException('playlist file has no playlists list');
    }
    return [
      for (final entry in raw) Playlist.tryParse(entry),
    ].whereType<Playlist>().toList();
  }

  @override
  Future<void> write(List<Playlist> playlists) async {
    final directory = await _directory();
    await directory.create(recursive: true);

    final target = await _file();
    final temp = await _file('.tmp');
    final document = {
      'version': version,
      'playlists': [for (final playlist in playlists) playlist.toJson()],
    };
    await temp.writeAsString(jsonEncode(document), flush: true);

    if (await target.exists()) {
      await target.copy((await _file('.prev')).path);
    }
    try {
      await temp.rename(target.path);
    } on FileSystemException {
      // Some systems will not rename over a file that exists.
      if (await target.exists()) await target.delete();
      await temp.rename(target.path);
    }
  }
}
