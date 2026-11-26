import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/search_history_entry.dart';

/// Where "Recent searches" is kept between runs.
abstract interface class SearchHistoryStore {
  /// The saved entries, newest first. Empty when there is no file yet or it
  /// cannot be understood, so a bad file never breaks the Search tab.
  Future<List<SearchHistoryEntry>> read();

  Future<void> write(List<SearchHistoryEntry> entries);
}

typedef SearchHistoryDirectory = Future<Directory> Function();

/// One small JSON file, written to a temporary name and renamed into place so
/// a crash in the middle of saving never leaves half a file. The test copy of
/// the app keeps its own file, like the playlists and the queue do, so it
/// never touches hers.
class FileSearchHistoryStore implements SearchHistoryStore {
  FileSearchHistoryStore({
    required SearchHistoryDirectory directory,
    this.profile,
    this.defaultProfile,
  }) : _directory = directory;

  static const int version = 1;

  /// The profile this copy of the app is, and the one whose file keeps the
  /// plain name (hers).
  final String? profile;
  final String? defaultProfile;

  final SearchHistoryDirectory _directory;

  String get fileName => profile == null || profile == defaultProfile
      ? 'search_history_v1.json'
      : 'search_history_${profile}_v1.json';

  // Writes go one after the other, so two never share the temporary file.
  Future<void> _last = Future.value();

  Future<File> _file([String suffix = '']) async {
    final directory = await _directory();
    return File('${directory.path}${Platform.pathSeparator}$fileName$suffix');
  }

  @override
  Future<List<SearchHistoryEntry>> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return const [];
      final body = jsonDecode(await file.readAsString());
      if (body is! Map || body['entries'] is! List) return const [];
      return [
        for (final raw in body['entries'] as List)
          if (SearchHistoryEntry.tryParse(raw) case final entry?) entry,
      ];
    } on FormatException {
      return const []; // damaged: the next save replaces it
    } on FileSystemException {
      return const [];
    }
  }

  @override
  Future<void> write(List<SearchHistoryEntry> entries) {
    final done = _last.then((_) => _write(entries));
    // A failed write must not stop the ones after it.
    _last = done.then((_) {}, onError: (_) {});
    return done;
  }

  Future<void> _write(List<SearchHistoryEntry> entries) async {
    final directory = await _directory();
    await directory.create(recursive: true);
    final target = await _file();
    final temp = await _file('.tmp');
    final body = jsonEncode({
      'version': version,
      'entries': [for (final entry in entries) entry.toJson()],
    });
    await temp.writeAsString(body, flush: true);
    try {
      await temp.rename(target.path);
    } on FileSystemException {
      // Some systems will not rename over a file that exists.
      if (await target.exists()) await target.delete();
      await temp.rename(target.path);
    }
  }
}
