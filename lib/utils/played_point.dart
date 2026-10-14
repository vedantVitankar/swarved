/// How far into the current song the listener really got.
///
/// The player cannot be asked this at the moment a song ends: on Windows and
/// Linux it resets its position to zero just before it says "completed". A
/// song that ended by itself then looks like one that was cut off at 0:00,
/// and is played again. This remembers the last real position instead.
class PlayedPoint {
  Duration _at = Duration.zero;

  /// The furthest recent position seen, or where a seek or a retry put it.
  Duration get at => _at;

  /// A position the player reported. A zero is ignored, because it is what
  /// the player says when it has finished and is not a place in the song.
  void see(Duration position) {
    if (position > Duration.zero) _at = position;
  }

  /// The listener (or a retry) moved the song to [position], zero included.
  void moveTo(Duration position) => _at = position;

  /// A different song, or the same one starting afresh.
  void reset() => _at = Duration.zero;
}

/// Whether a stream stopped well before the song's length, so it was cut
/// short and did not finish. False when the length is not known.
bool endedEarly({
  required Duration reached,
  required Duration total,
  required Duration margin,
}) {
  if (total <= Duration.zero) return false;
  return reached < total - margin;
}
