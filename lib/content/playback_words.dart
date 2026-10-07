import '../models/playback_problem.dart';

/// What the player says when a song can't play. Kept short on purpose: the
/// mini player shows it on a single line in place of the artist's name.
class PlaybackWords {
  PlaybackWords._();

  static String forProblem(PlaybackProblem problem) => switch (problem) {
        PlaybackProblem.noToken => 'Add your token in Us first.',
        PlaybackProblem.unauthorized => 'Token not accepted. Check Us.',
        PlaybackProblem.unavailable => 'Not available on YouTube anymore.',
        PlaybackProblem.unreachable => 'Can’t reach the server. Tap play.',
        PlaybackProblem.timeout => 'Taking too long. Tap play to retry.',
        PlaybackProblem.connectionLost => 'Connection dropped. Tap play.',
        PlaybackProblem.serverTrouble => 'YouTube said no. Tap play to retry.',
        PlaybackProblem.unexpected => 'Something went sideways. Tap play.',
      };
}
