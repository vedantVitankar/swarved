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

  /// The position a skip would go to next, without moving. Null when there
  /// is no next song, or when it can't be known yet: with shuffle and repeat
  /// all, the next round is only shuffled once this one ends.
  int? get upcomingIndex {
    if (_order.isEmpty) return null;
    if (_cursor < _order.length - 1) return _order[_cursor + 1];
    if (repeat == QueueRepeat.all && !_shuffle) return _order[0];
    return null;
  }

  /// Begins a new queue of [length] songs, playing [startIndex] first.
  /// Everything needed to put this order back exactly as it is, for saving
  /// between sessions: the play order, where we are in it, shuffle and repeat.
  Map<String, Object?> toJson() => {
        'order': List<int>.of(_order),
        'cursor': _cursor,
        'shuffle': _shuffle,
        'repeat': repeat.name,
      };

  /// Puts back what [toJson] wrote, for a queue of [length] songs. Returns
  /// false, and changes nothing, when it does not fit that queue: the order
  /// must be every position from 0 to length - 1 once, and the cursor must be
  /// one of them. The caller then starts a fresh order instead.
  bool restore(Object? json, {required int length}) {
    if (json is! Map || length <= 0) return false;
    final order = json['order'];
    final cursor = json['cursor'];
    final shuffle = json['shuffle'];
    final repeatName = json['repeat'];
    if (order is! List || order.length != length) return false;
    if (cursor is! int || cursor < 0 || cursor >= length) return false;
    if (shuffle is! bool) return false;
    final parsed = QueueRepeat.values.where((r) => r.name == repeatName);
    if (parsed.isEmpty) return false;

    final seen = <int>{};
    for (final position in order) {
      if (position is! int || position < 0 || position >= length) return false;
      if (!seen.add(position)) return false; // a position twice
    }

    _order = [for (final position in order) position as int];
    _cursor = cursor;
    _shuffle = shuffle;
    repeat = parsed.first;
    return true;
  }

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

  /// The queue changed under a playing order: songs were added, taken out or
  /// moved, and [newLength] songs are there now. [oldToNew] says where each
  /// old position went (null when it is gone) and [added] lists the positions
  /// that are new. The song now playing, and the one after it, stay as they
  /// are; nothing is reshuffled.
  ///
  /// With shuffle off the order simply follows the new queue. With shuffle on
  /// the order that was drawn is kept, and each new song is slipped in at a
  /// random place among the songs still to come, so it is heard this round.
  void remap({
    required List<int?> oldToNew,
    required int newLength,
    required List<int> added,
  }) {
    if (newLength <= 0) {
      _order = [];
      _cursor = -1;
      return;
    }
    if (_order.isEmpty) {
      _order = _natural(newLength);
      if (_shuffle) _order.shuffle(_random);
      _cursor = 0;
      return;
    }

    if (!_shuffle) {
      final playing = _cursor >= 0 && _cursor < _order.length
          ? _order[_cursor]
          : null;
      _order = _natural(newLength);
      _cursor = playing == null
          ? newLength
          : _positionAtOrAfter(playing, oldToNew, newLength);
      return;
    }

    final kept = <int>[];
    var cursor = kept.length;
    for (var i = 0; i < _order.length; i++) {
      final moved = oldToNew[_order[i]];
      // The cursor is the index its song gets, or, if that song is gone, the
      // index of the next one that stays.
      if (i == _cursor) cursor = kept.length;
      if (moved != null) kept.add(moved);
    }
    if (_cursor < 0 || _cursor >= _order.length) cursor = kept.length;

    final fresh = List<int>.of(added)..shuffle(_random);
    for (final position in fresh) {
      final first = min(cursor + 1, kept.length);
      kept.insert(first + _random.nextInt(kept.length - first + 1), position);
    }
    _order = kept;
    _cursor = cursor;
  }

  /// Where old position [old] is now, or where the next song that stayed is,
  /// or [newLength] when nothing after it stayed.
  int _positionAtOrAfter(int old, List<int?> oldToNew, int newLength) {
    for (var i = old; i < oldToNew.length; i++) {
      final moved = oldToNew[i];
      if (moved != null) return moved;
    }
    return newLength;
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
