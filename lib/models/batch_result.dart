import 'save_problem.dart';

/// How saving a whole playlist ended.
class BatchResult {
  const BatchResult({
    required this.folderName,
    this.saved = 0,
    this.alreadySaved = 0,
    this.failed = 0,
    this.stoppedBy,
    this.cancelled = false,
  });

  /// The folder the songs went into, named after the playlist.
  final String folderName;

  /// Songs downloaded this time.
  final int saved;

  /// Songs that were saved before, so nothing was downloaded for them.
  final int alreadySaved;

  /// Songs that could not be saved, and are worth trying again.
  final int failed;

  /// The problem that made the whole run stop, when there was one: no token,
  /// no connection, no room. Null when every song got its turn.
  final SaveProblem? stoppedBy;

  /// True when the listener stopped it.
  final bool cancelled;

  /// True when there was nothing left to download.
  bool get nothingToDo => saved == 0 && failed == 0 && stoppedBy == null;
}
