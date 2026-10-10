/// When things happen in the first minutes on Home: the greeting types
/// itself in the middle of a blank screen, glides up to where it lives, and
/// the rest of Home fades in around it. Pure numbers, so it can be tested
/// without a screen.
class TutorialTimeline {
  TutorialTimeline._();

  /// How long each letter takes, and the least the whole greeting takes, so
  /// a short one doesn't flash by.
  static const Duration perLetter = Duration(milliseconds: 75);
  static const Duration minTyping = Duration(milliseconds: 1400);

  /// A held breath between the last letter and the glide.
  static const Duration pause = Duration(milliseconds: 700);

  /// The glide up to the greeting's real place.
  static const Duration glide = Duration(milliseconds: 1100);

  /// Each block of Home starts this long after the one before it, and takes
  /// [revealFade] to arrive.
  static const Duration revealGap = Duration(milliseconds: 220);
  static const Duration revealFade = Duration(milliseconds: 550);

  /// A moment to rest before the intro hands over.
  static const Duration settle = Duration(milliseconds: 400);

  /// What fades in without a tutorial song, in order: 0 the subline, 1 the
  /// filter chips, 2 the folders, 3 the song of the day, 4 the mini player
  /// and navigation bar. With a tutorial song only the song comes first, and
  /// the rest follows once she has pressed play. The home note comes last.
  static const int revealBlocks = 5;

  /// How long the typing takes for a greeting of [letters] characters.
  static Duration typing(int letters) {
    final natural = perLetter * letters;
    return natural < minTyping ? minTyping : natural;
  }

  /// How many characters are showing [elapsed] after the typing began.
  static int lettersShown(Duration elapsed, int letters) {
    if (letters <= 0 || elapsed <= Duration.zero) return 0;
    final total = typing(letters).inMilliseconds;
    if (elapsed.inMilliseconds >= total) return letters;
    return (letters * elapsed.inMilliseconds / total).floor();
  }

  static Duration glideStart(int letters) => typing(letters) + pause;

  static Duration glideEnd(int letters) => glideStart(letters) + glide;

  /// From the first of [blocks] starting to the last one arriving.
  static Duration revealFor(int blocks) =>
      revealFade + revealGap * (blocks > 1 ? blocks - 1 : 0);

  /// The reveal of every block.
  static Duration get revealDuration => revealFor(revealBlocks);

  /// When the opening is over, with [blocks] fading in at the end of it.
  static Duration end(int letters, {int blocks = revealBlocks}) =>
      glideEnd(letters) + revealFor(blocks) + settle;
}
