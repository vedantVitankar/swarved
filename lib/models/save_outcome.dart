import 'save_problem.dart';

/// How one attempt to save a song ended.
sealed class SaveOutcome {
  const SaveOutcome();
}

/// The song is now a file in the library folder, at [path].
final class SaveDone extends SaveOutcome {
  const SaveDone(this.path);
  final String path;
}

/// The song was saved earlier and its file is still there at [path].
/// Nothing was downloaded.
final class SaveAlreadyThere extends SaveOutcome {
  const SaveAlreadyThere(this.path);
  final String path;
}

/// Nothing was saved, for the reason in [problem].
final class SaveFailed extends SaveOutcome {
  const SaveFailed(this.problem);
  final SaveProblem problem;
}
