import 'track.dart';

/// The song the tutorial plays: the bundled file, ready to play, with the
/// words that go on its card. Apart from the song of the day in the content
/// file, so a content push can never change what the tutorial plays.
class TutorialSong {
  final Track track;

  /// The gold line above the card. Null uses the default.
  final String? label;

  /// A handwritten line on the card. Null shows none.
  final String? note;

  const TutorialSong({required this.track, this.label, this.note});
}
