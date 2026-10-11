import '../models/batch_result.dart';
import '../models/save_problem.dart';

/// What the save button says. Short on purpose: the problem messages appear
/// in a snackbar over the list.
class SaveWords {
  SaveWords._();

  static const save = 'Save to library';
  static const saving = 'Saving…';
  static const saved = 'Saved';
  static const retry = 'Try saving again';

  static const done = 'Saved to your library.';
  static const alreadySaved = 'Already saved.';

  // Saving a whole playlist.
  static const downloadAll = 'Download all';
  static const stopDownloading = 'Stop downloading';
  static const allDownloaded = 'All downloaded';

  static String downloadingProgress(int finished, int total) =>
      'Downloading ${finished + 1 > total ? total : finished + 1} of $total';

  static const stoppingAfterThis = 'Stopping after this song…';

  /// What the snackbar says when a playlist's download ends.
  static String forBatch(BatchResult result) {
    final problem = result.stoppedBy;
    if (problem != null) {
      final head = result.saved == 0
          ? ''
          : 'Saved ${_songs(result.saved)} to ${_quoted(result.folderName)}. ';
      return '$head${forProblem(problem)}';
    }
    if (result.cancelled) {
      return result.saved == 0
          ? 'Stopped.'
          : 'Stopped. ${_songs(result.saved)} saved to '
              '${_quoted(result.folderName)}.';
    }
    if (result.nothingToDo) return 'Everything here is already saved.';
    final head =
        'Saved ${_songs(result.saved)} to ${_quoted(result.folderName)}.';
    if (result.failed == 0) return head;
    return '$head ${_songs(result.failed)} couldn’t be saved. '
        'Tap download to try them again.';
  }

  static String _songs(int count) => count == 1 ? '1 song' : '$count songs';
  static String _quoted(String name) => '“$name”';

  // The question before the folder picker, the first time she saves a song.
  static const folderPromptTitle = 'Where should it live?';
  static const folderPromptBody =
      'Pick a folder on this device for the songs you save. They stay here, just yours.';

  static String forProblem(SaveProblem problem) => switch (problem) {
        SaveProblem.noToken => 'Add your token in Us first.',
        SaveProblem.unauthorized => 'Token not accepted. Check Us.',
        SaveProblem.unavailable => 'Not available on YouTube anymore.',
        SaveProblem.serverBusy => 'The server is busy. Try again in a moment.',
        SaveProblem.serverTrouble =>
          'The server couldn’t prepare this song. Try again.',
        SaveProblem.unreachable => 'Can’t reach the server.',
        SaveProblem.timeout => 'Taking too long. Try again.',
        SaveProblem.connectionLost => 'Connection dropped. Try again.',
        SaveProblem.folderMissing =>
          'Music folder not found. Choose it in Library.',
        SaveProblem.noFolder => 'Pick a music folder to save songs into.',
        SaveProblem.cannotWrite => 'Can’t write to your music folder.',
        SaveProblem.diskFull => 'Not enough space on this device.',
        SaveProblem.unexpected => 'Something went sideways. Try again.',
      };
}
