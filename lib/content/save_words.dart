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
        SaveProblem.cannotWrite => 'Can’t write to your music folder.',
        SaveProblem.diskFull => 'Not enough space on this device.',
        SaveProblem.unexpected => 'Something went sideways. Try again.',
      };
}
