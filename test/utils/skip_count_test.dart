import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/utils/skip_count.dart';

void main() {
  group('skipCounts', () {
    test('leaving a song she was listening to for a different one counts', () {
      expect(
        skipCounts(listening: true, playingId: 'yt:a', chosenId: 'yt:b'),
        isTrue,
      );
    });

    test('the same song again is a restart, not a skip', () {
      expect(
        skipCounts(listening: true, playingId: 'yt:a', chosenId: 'yt:a'),
        isFalse,
      );
    });

    test('nothing was being listened to: it does not count', () {
      // A voice recording, a letter, a queue restored at start-up, a song
      // that failed to load.
      expect(
        skipCounts(listening: false, playingId: 'yt:a', chosenId: 'yt:b'),
        isFalse,
      );
    });

    test('nothing was playing at all: the first song does not count', () {
      expect(
        skipCounts(listening: true, playingId: null, chosenId: 'yt:b'),
        isFalse,
      );
    });

    test('no song to go to: it does not count', () {
      expect(
        skipCounts(listening: true, playingId: 'yt:a', chosenId: null),
        isFalse,
      );
    });
  });
}
