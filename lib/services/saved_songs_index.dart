import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kSavedSongsKey = 'saved_songs_v1';

/// Remembers which YouTube songs were saved, and where, so the same song is
/// never saved twice and search can say "Saved". A song counts as saved only
/// while its file still exists: delete the file and it can be saved again.
class SavedSongsIndex extends ChangeNotifier {
  SavedSongsIndex({bool Function(String path)? fileExists})
      : _fileExists = fileExists ?? ((path) => File(path).existsSync());

  final bool Function(String path) _fileExists;
  final Map<String, String> _paths = {};

  /// Reads the saved list. Never throws: damaged data just means an empty
  /// list, and the songs already on disk are untouched.
  Future<void> load() async {
    _paths.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kSavedSongsKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            final path = entry.value;
            if (path is String && path.isNotEmpty) _paths[entry.key] = path;
          }
        }
      }
    } catch (_) {
      _paths.clear();
    }
    notifyListeners();
  }

  /// Where the song was saved, or null when it hasn't been, or its file is
  /// gone.
  String? pathFor(String videoId) {
    final path = _paths[videoId];
    return path != null && _fileExists(path) ? path : null;
  }

  bool isSaved(String videoId) => pathFor(videoId) != null;

  Future<void> record(String videoId, String path) async {
    _paths[videoId] = path;
    notifyListeners();
    await _persist();
  }

  Future<void> forget(String videoId) async {
    if (_paths.remove(videoId) == null) return;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSavedSongsKey, jsonEncode(_paths));
  }
}
