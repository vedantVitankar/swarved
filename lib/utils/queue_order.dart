import 'dart:math';

/// What happens when a song ends.
enum QueueRepeat { off, all, one }

/// The rules for which song plays after which, with no audio involved so
/// they can be tested on their own.
///
/// It works on positions in the queue (0 for the first song, 1 for the
/// second, and so on), never on songs themselves. With shuffle on it keeps
/// its own play order; with shuffle off the order is simply 0, 1, 2...
class QueueOrder {
  QueueOrder({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Queue positions in the order they will play, and where we are in it.
  List<int> _order = [];
  int _cursor = -1;
  bool _shuffle = false;

  QueueRepeat repeat = QueueRepeat.off;

  bool get shuffle => _shuffle;

  /// The queue position now playing, or null when nothing is queued.
  int? get currentIndex =>
      _cursor >= 0 && _cursor < _order.length ? _order[_cursor] : null;

  bool get hasNext =>
      _order.isNotEmpty &&
      (_cursor < _order.length - 1 || repeat == QueueRepeat.all);

  bool get hasPrevious =>
      _order.isNotEmpty && (_cursor > 0 || repeat == QueueRepeat.all);

  /// Begins a new queue of [length] songs, playing [startIndex] first.
  void start({required int length, required int startIndex}) {
    if (length <= 0) {
      _order = [];
      _cursor = -1;
      return;
    }
    final first = min(max(startIndex, 0), length - 1);
    if (_shuffle) {
      _order = _shuffledStartingWith(first, length);
      _cursor = 0;
    } else {
      _order = _natural(length);
      _cursor = first;
    }
  }

  /// Switches shuffle on or off without changing the song now playing.
  void setShuffle(bool on) {
    if (on == _shuffle) return;
    _shuffle = on;
    final now = currentIndex;
    if (now == null) return;
    if (on) {
      _order = _shuffledStartingWith(now, _order.length);
      _cursor = 0;
    } else {
      _order = _natural(_order.length);
      _cursor = now;
    }
  }

  /// Moves to the next song and returns its position, or null when there
  /// is none (the end of the queue, with repeat not set to all).
  int? advance() {
    if (_order.isEmpty) return null;
    if (_cursor < _order.length - 1) {
      _cursor++;
    } else if (repeat == QueueRepeat.all) {
      _startNextRound();
    } else {
      return null;
    }
    return _order[_cursor];
  }

  /// Moves to the previous song and returns its position, or null.
  int? back() {
    if (_order.isEmpty) return null;
    if (_cursor > 0) {
      _cursor--;
    } else if (repeat == QueueRepeat.all) {
      _cursor = _order.length - 1;
    } else {
      return null;
    }
    return _order[_cursor];
  }

  /// A song finished by itself: what plays now? The same one for repeat
  /// one, otherwise the next one, or null when playback should stop.
  int? onSongEnded() => repeat == QueueRepeat.one ? currentIndex : advance();

  void _startNextRound() {
    if (_shuffle && _order.length > 1) {
      final lastPlayed = _order[_cursor];
      final fresh = _natural(_order.length)..shuffle(_random);
      // Never open the new round with the song that just ended.
      if (fresh.first == lastPlayed) {
        final swapWith = 1 + _random.nextInt(fresh.length - 1);
        final held = fresh[0];
        fresh[0] = fresh[swapWith];
        fresh[swapWith] = held;
      }
      _order = fresh;
    }
    _cursor = 0;
  }

  List<int> _natural(int length) => List.generate(length, (i) => i);

  List<int> _shuffledStartingWith(int first, int length) {
    final rest = [
      for (var i = 0; i < length; i++)
        if (i != first) i,
    ]..shuffle(_random);
    return [first, ...rest];
  }
}
