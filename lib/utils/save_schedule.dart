/// Decides when the player's state is worth writing to disk, so it is saved
/// often enough to lose almost nothing and rarely enough not to wear the disk.
/// It has no timers and no files: it is asked, with the time, and answers.
///
/// The state is split in two. The *signature* is everything except how far
/// into the song she is (which queue, which song, shuffle, repeat, which
/// playlist). It changes only when she does something, and a burst of changes
/// (skipping through five songs) is written once, when it has settled.
/// The *position* moves all the time, so while a song plays it is written
/// every [positionEvery].
class SaveSchedule {
  SaveSchedule({
    this.positionEvery = const Duration(seconds: 10),
    this.settle = const Duration(milliseconds: 400),
    this.seekedBy = const Duration(seconds: 2),
  });

  final Duration positionEvery;
  final Duration settle;

  /// A move of the position, while paused, that counts as worth saving.
  final Duration seekedBy;

  String? _savedSignature;
  Duration _savedPosition = Duration.zero;
  DateTime? _lastSave;

  String? _waitingSignature;
  DateTime? _waitingSince;

  bool _wasPlaying = false;
  bool _force = false;

  /// Asked often (every time the player changes, and from a timer): is it time
  /// to write? When this says true the caller writes and then calls [saved].
  bool shouldSave({
    required String signature,
    required bool playing,
    required Duration position,
    required DateTime now,
  }) {
    final justPaused = _wasPlaying && !playing;
    _wasPlaying = playing;

    if (_force) return true;

    if (signature != _savedSignature) {
      // Something changed. Wait until it stops changing.
      if (signature != _waitingSignature) {
        _waitingSignature = signature;
        _waitingSince = now;
      }
      return now.difference(_waitingSince!) >= settle;
    }
    _waitingSignature = null;

    if (justPaused) return true; // the place she stopped at

    if (playing) {
      final last = _lastSave;
      return last == null || now.difference(last) >= positionEvery;
    }

    // Paused or stopped: only a real move of the position is news.
    return (position - _savedPosition).abs() >= seekedBy;
  }

  /// The caller wrote [signature] and [position] to disk.
  void saved({
    required String signature,
    required Duration position,
    required DateTime now,
  }) {
    _savedSignature = signature;
    _savedPosition = position;
    _lastSave = now;
    _waitingSignature = null;
    _force = false;
  }

  /// The next question is answered "yes" whatever the state, for when the app
  /// is about to go to the background and may not be back.
  void saveNext() => _force = true;
}
