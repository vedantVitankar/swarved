/// Notices a song that is meant to be playing but has stopped moving.
///
/// When a stream is cut, the player does not always say so: it can keep
/// claiming to play while the position stands still. Feed this the position
/// every couple of seconds; it says true once the song has stood still for
/// too long (longer when the player says it is waiting for more of the song).
class StallDetector {
  StallDetector({
    this.limit = const Duration(seconds: 8),
    this.bufferingLimit = const Duration(seconds: 25),
  });

  /// How long a song may stand still while playing.
  final Duration limit;

  /// How long it may stand still while the player is buffering.
  final Duration bufferingLimit;

  Duration? _position;
  DateTime? _since;

  /// One look at the player. [expectingSound] is false whenever standing
  /// still is fine (paused, loading, a local song, the very end of a song).
  /// Answers true when the song has stood still too long; it then starts
  /// counting again, so it says true once per [limit], not on every look.
  bool tick({
    required Duration position,
    required bool expectingSound,
    required bool buffering,
    required DateTime now,
  }) {
    if (!expectingSound || position != _position) {
      _position = position;
      _since = now;
      return false;
    }
    final stood = now.difference(_since ?? now);
    if (stood >= (buffering ? bufferingLimit : limit)) {
      _since = now;
      return true;
    }
    return false;
  }

  /// Forget what was seen, as when a new song starts loading.
  void reset() {
    _position = null;
    _since = null;
  }
}
