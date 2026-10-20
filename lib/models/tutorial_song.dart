import 'track.dart';

/// The song the welcome offers: the bundled file, ready to play. Apart from
/// the song of the day in the content file, so a content push can never
/// change what the welcome plays.
class TutorialSong {
  final Track track;

  /// Once the gold line above the song's card. Read, but not shown.
  final String? label;

  /// Once a handwritten line on the song's card. Read, but not shown.
  final String? note;

  const TutorialSong({required this.track, this.label, this.note});
}
