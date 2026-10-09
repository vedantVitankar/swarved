import 'package:flutter/foundation.dart';

import '../models/save_problem.dart';
import '../models/youtube_result.dart';
import 'saved_songs_index.dart';
import 'song_saver.dart';

/// What a song's save button shows.
enum SaveStage { idle, saving, saved, failed }

/// A song's stage, and how far a save has got in whole percent. The percent
/// is null when nothing is saving, or while the server is still converting
/// and hasn't said how big the file is. A record, so a Selector can compare
/// two of them.
typedef SaveView = (SaveStage, int?);

/// The saver's save method, so tests can stand in for it.
typedef SaveCall = Future<SaveOutcome> Function(
  YoutubeResult song, {
  required String folderPath,
  void Function(int received, int? total)? onProgress,
});

/// Asks the listener for a music folder. Answers with its path, or null when
/// none was chosen.
typedef FolderChooser = Future<String?> Function();

/// Keeps track of every save in progress or failed, for the buttons on the
/// search results. Which songs are already saved comes from the index.
class SaveController extends ChangeNotifier {
  SaveController({
    required SaveCall save,
    required SavedSongsIndex index,
    required String? Function() folderPath,
    required Future<void> Function(String path) onSaved,
    FolderChooser? chooseFolder,
  })  : _save = save,
        _index = index,
        _folderPath = folderPath,
        _onSaved = onSaved,
        _chooseFolder = chooseFolder {
    _index.addListener(_notify);
  }

  final SaveCall _save;
  final SavedSongsIndex _index;
  final String? Function() _folderPath;
  final Future<void> Function(String path) _onSaved;

  /// How the very first save finds a folder. Without one, a save with no
  /// folder just fails.
  final FolderChooser? _chooseFolder;

  /// True while the folder picker is open, so a second tap can't open another.
  bool _choosing = false;

  /// Songs being saved right now, with their progress in whole percent.
  final Map<String, int?> _saving = {};

  /// Songs whose last save failed, and why.
  final Map<String, SaveProblem> _failed = {};

  bool _disposed = false;

  SaveView viewOf(String videoId) {
    if (_saving.containsKey(videoId)) {
      return (SaveStage.saving, _saving[videoId]);
    }
    if (_index.isSaved(videoId)) {
      return (SaveStage.saved, null);
    }
    if (_failed.containsKey(videoId)) {
      return (SaveStage.failed, null);
    }
    return (SaveStage.idle, null);
  }

  SaveProblem? problemOf(String videoId) => _failed[videoId];

  /// True when a save would have to ask for a folder first.
  bool get needsFolder => _chooseFolder != null && _folderPath() == null;

  /// Saves [song] into the library folder, asking for the folder first when
  /// there is none. Returns null when the song is already being saved or the
  /// folder picker is already open, so a second tap does nothing. Closing
  /// the picker without a folder fails with [SaveProblem.noFolder] and leaves
  /// the song as it was, ready to try again. Never throws.
  Future<SaveOutcome?> save(YoutubeResult song) async {
    final id = song.id;
    if (_saving.containsKey(id)) return null;

    var folder = _folderPath();
    if (folder == null && _chooseFolder != null) {
      if (_choosing) return null;
      folder = await _askForFolder();
      if (folder == null) return const SaveFailed(SaveProblem.noFolder);
    }
    if (folder == null) {
      _failed[id] = SaveProblem.folderMissing;
      _notify();
      return const SaveFailed(SaveProblem.folderMissing);
    }

    _failed.remove(id);
    _saving[id] = null;
    _notify();

    final outcome = await _run(song, folder);
    _saving.remove(id);

    final path = switch (outcome) {
      SaveDone(:final path) => path,
      SaveAlreadyThere(:final path) => path,
      SaveFailed() => null,
    };
    if (path != null) {
      await _listQuietly(path);
    } else if (outcome is SaveFailed) {
      _failed[id] = outcome.problem;
    }
    _notify();
    return outcome;
  }

  Future<String?> _askForFolder() async {
    _choosing = true;
    try {
      return await _chooseFolder!();
    } catch (_) {
      return null;
    } finally {
      _choosing = false;
    }
  }

  Future<SaveOutcome> _run(YoutubeResult song, String folder) async {
    try {
      return await _save(
        song,
        folderPath: folder,
        onProgress: (received, total) => _onProgress(song.id, received, total),
      );
    } catch (_) {
      return const SaveFailed(SaveProblem.unexpected);
    }
  }

  /// Only tells listeners when the whole percent changes.
  void _onProgress(String id, int received, int? total) {
    if (!_saving.containsKey(id)) return;
    int? percent;
    if (total != null && total > 0) {
      final raw = received * 100 ~/ total;
      percent = raw > 100 ? 100 : raw;
    }
    if (_saving[id] == percent) return;
    _saving[id] = percent;
    _notify();
  }

  /// The file is saved whether or not the list can show it yet.
  Future<void> _listQuietly(String path) async {
    try {
      await _onSaved(path);
    } catch (_) {
      // Nothing to tell the listener: the song is in the folder.
    }
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
