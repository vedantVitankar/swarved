import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/saved_queue.dart';

/// Where the queue she was playing is kept between sessions.
abstract interface class SavedQueueStore {
  /// The saved queue, or null when there is none or it is unusable.
  Future<SavedQueue?> read();

  Future<void> write(SavedQueue saved);

  Future<void> clear();
}

typedef QueueDirectory = Future<Directory> Function();

/// One small JSON file, written to a temporary name and renamed into place so
/// a crash in the middle of saving never leaves half a file. The test copy of
/// the app keeps its own file, like the playlists do, so it never touches hers.
class FileSavedQueueStore implements SavedQueueStore {
  FileSavedQueueStore({
    required QueueDirectory directory,
    this.profile,
    this.defaultProfile,
  }) : _directory = directory;

  /// The profile this copy of the app is, and the one whose files keep the
  /// plain name (hers).
  final String? profile;
  final String? defaultProfile;

  final QueueDirectory _directory;

  String get fileName => profile == null || profile == defaultProfile
      ? 'queue_v1.json'
      : 'queue_${profile}_v1.json';

  // Writes go one after the other, so two never share the temporary file.
  Future<void> _last = Future.value();

  Future<File> _file([String suffix = '']) async {
    final directory = await _directory();
    return File('${directory.path}${Platform.pathSeparator}$fileName$suffix');
  }

  @override
  Future<SavedQueue?> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      return SavedQueue.tryParse(jsonDecode(await file.readAsString()));
    } on FormatException {
      return null; // damaged: the next save replaces it
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<void> write(SavedQueue saved) {
    final done = _last.then((_) => _write(saved));
    // A failed write must not stop the ones after it.
    _last = done.then((_) {}, onError: (_) {});
    return done;
  }

  Future<void> _write(SavedQueue saved) async {
    final directory = await _directory();
    await directory.create(recursive: true);
    final target = await _file();
    final temp = await _file('.tmp');
    await temp.writeAsString(jsonEncode(saved.toJson()), flush: true);
    try {
      await temp.rename(target.path);
    } on FileSystemException {
      // Some systems will not rename over a file that exists.
      if (await target.exists()) await target.delete();
      await temp.rename(target.path);
    }
  }

  @override
  Future<void> clear() {
    final done = _last.then((_) async {
      final file = await _file();
      if (await file.exists()) await file.delete();
    });
    _last = done.then((_) {}, onError: (_) {});
    return done;
  }
}
