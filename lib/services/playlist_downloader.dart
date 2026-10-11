import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/batch_result.dart';
import '../models/save_problem.dart';
import '../models/youtube_result.dart';
import '../utils/song_file_name.dart';
import 'save_controller.dart';
import 'saved_songs_index.dart';
import 'song_saver.dart';
import 'song_writer.dart';

/// Makes a folder, and any folder above it that is missing.
typedef FolderMaker = Future<void> Function(String path);

/// How far a playlist's download has got.
class BatchView {
  const BatchView({
    required this.finished,
    required this.total,
    this.stopping = false,
  });

  /// Songs that have had their turn, whether they saved or not.
  final int finished;
  final int total;

  /// True once the listener asked to stop; the song in flight still ends.
  final bool stopping;
}

class _Run {
  _Run(this.total);

  final int total;
  int finished = 0;
  bool cancelled = false;
}

/// Saves every YouTube song of a playlist, one after another, into a folder
/// named after the playlist inside the library folder. Each song goes
/// through the [SaveController], so its own save button shows the progress
/// too. Only runs when the listener asks.
///
/// One song at a time on purpose: the server converts each song before it
/// sends it, and a playlist should not flood it.
class PlaylistDownloader extends ChangeNotifier {
  PlaylistDownloader({
    required SaveController saves,
    required SavedSongsIndex index,
    FolderMaker? makeFolder,
  })  : _saves = saves,
        _index = index,
        _makeFolder = makeFolder ?? _createFolder {
    _index.addListener(_notify);
  }

  final SaveController _saves;
  final SavedSongsIndex _index;
  final FolderMaker _makeFolder;

  final Map<String, _Run> _runs = {};
  bool _disposed = false;

  static Future<void> _createFolder(String path) async {
    await Directory(path).create(recursive: true);
  }

  /// Problems that no other song can get past, so the run stops at once.
  /// Anything else is that one song's trouble, and the run goes on.
  static bool stopsRun(SaveProblem problem) => switch (problem) {
        SaveProblem.noToken ||
        SaveProblem.unauthorized ||
        SaveProblem.unreachable ||
        SaveProblem.folderMissing ||
        SaveProblem.noFolder ||
        SaveProblem.cannotWrite ||
        SaveProblem.diskFull =>
          true,
        _ => false,
      };

  /// Null when [playlistId] is not downloading.
  BatchView? viewOf(String playlistId) {
    final run = _runs[playlistId];
    if (run == null) return null;
    return BatchView(
      finished: run.finished,
      total: run.total,
      stopping: run.cancelled,
    );
  }

  bool isRunning(String playlistId) => _runs.containsKey(playlistId);

  /// How many of [songs] still have no saved file.
  int missingCount(Iterable<YoutubeResult> songs) =>
      songs.where((song) => !_index.isSaved(song.id)).length;

  /// Asks the run for [playlistId] to stop after the song it is on.
  void cancel(String playlistId) {
    final run = _runs[playlistId];
    if (run == null || run.cancelled) return;
    run.cancelled = true;
    _notify();
  }

  /// Saves the songs of [songs] that are not saved yet into a folder named
  /// [playlistName] inside the library folder, asking for the library
  /// folder first when there is none. Returns null when this playlist is
  /// already downloading. Never throws.
  Future<BatchResult?> download({
    required String playlistId,
    required String playlistName,
    required List<YoutubeResult> songs,
  }) async {
    if (_runs.containsKey(playlistId)) return null;

    final folderName = safeFolderName(playlistName);
    final todo = [
      for (final song in songs)
        if (!_index.isSaved(song.id)) song,
    ];
    final alreadySaved = songs.length - todo.length;
    if (todo.isEmpty) {
      return BatchResult(folderName: folderName, alreadySaved: alreadySaved);
    }

    // Claimed before the first wait, so a second tap can't start a second run.
    final run = _Run(todo.length);
    _runs[playlistId] = run;
    _notify();

    try {
      final root = await _saves.ensureFolder();
      if (root == null) {
        return BatchResult(
          folderName: folderName,
          alreadySaved: alreadySaved,
          stoppedBy: SaveProblem.noFolder,
        );
      }

      final folder = p.join(root, folderName);
      try {
        await _makeFolder(folder);
      } on FileSystemException catch (e) {
        return BatchResult(
          folderName: folderName,
          alreadySaved: alreadySaved,
          stoppedBy: _problemForFolder(e),
        );
      } catch (_) {
        return BatchResult(
          folderName: folderName,
          alreadySaved: alreadySaved,
          stoppedBy: SaveProblem.unexpected,
        );
      }

      var saved = 0;
      var failed = 0;
      var already = alreadySaved;
      SaveProblem? stoppedBy;

      for (final song in todo) {
        if (run.cancelled) break;
        final outcome = await _saves.save(song, intoFolder: folder);
        switch (outcome) {
          case SaveDone():
            saved++;
          case SaveAlreadyThere():
            already++;
          case null:
            // Being saved from its own button right now; that save finishes
            // by itself.
            already++;
          case SaveFailed(:final problem):
            if (stopsRun(problem)) {
              stoppedBy = problem;
            } else {
              failed++;
            }
        }
        run.finished++;
        _notify();
        if (stoppedBy != null) break;
      }

      return BatchResult(
        folderName: folderName,
        saved: saved,
        alreadySaved: already,
        failed: failed,
        stoppedBy: stoppedBy,
        cancelled: run.cancelled && stoppedBy == null,
      );
    } finally {
      _runs.remove(playlistId);
      _notify();
    }
  }

  /// A folder that cannot be made is a write problem. "Not found" would be
  /// misleading: the library folder was there a moment ago.
  SaveProblem _problemForFolder(FileSystemException error) {
    final problem = problemForFileError(error);
    return problem == SaveProblem.folderMissing
        ? SaveProblem.cannotWrite
        : problem;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _index.removeListener(_notify);
    super.dispose();
  }
}
