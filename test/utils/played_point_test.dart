import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/utils/played_point.dart';

const _margin = Duration(seconds: 8);
Duration _s(int seconds) => Duration(seconds: seconds);

void main() {
  group('PlayedPoint', () {
    test('starts at the beginning', () {
      expect(PlayedPoint().at, Duration.zero);
    });

    test('follows the positions the player reports', () {
      final point = PlayedPoint()
        ..see(_s(10))
        ..see(_s(11));
      expect(point.at, _s(11));
    });

    test('a zero from the player is not a place in the song', () {
      // What media_kit says the moment a song has ended.
      final point = PlayedPoint()
        ..see(_s(209))
        ..see(Duration.zero);
      expect(point.at, _s(209));
    });

    test('a seek is remembered, even back to the start', () {
      final point = PlayedPoint()
        ..see(_s(150))
        ..moveTo(Duration.zero);
      expect(point.at, Duration.zero);
      point.see(_s(1));
      expect(point.at, _s(1));
    });

    test('a retry resumes from where the song was dropped', () {
      final point = PlayedPoint()..moveTo(_s(70));
      expect(point.at, _s(70));
    });

    test('reset goes back to the beginning', () {
      final point = PlayedPoint()
        ..see(_s(90))
        ..reset();
      expect(point.at, Duration.zero);
    });
  });

  group('endedEarly', () {
    test('a song that played to its end did not end early', () {
      expect(
        endedEarly(reached: _s(209), total: _s(210), margin: _margin),
        isFalse,
      );
    });

    test('a stream cut in the middle ended early', () {
      expect(
        endedEarly(reached: _s(70), total: _s(210), margin: _margin),
        isTrue,
      );
    });

    test('exactly the margin before the end is still the end', () {
      expect(
        endedEarly(reached: _s(202), total: _s(210), margin: _margin),
        isFalse,
      );
      expect(
        endedEarly(reached: _s(201), total: _s(210), margin: _margin),
        isTrue,
      );
    });

    test('an unknown length is never early', () {
      expect(
        endedEarly(reached: _s(5), total: Duration.zero, margin: _margin),
        isFalse,
      );
    });

    test('the end of a song is judged by the last real position, not zero',
        () {
      // The bug: the player reads zero once a song has ended, so a finished
      // song looked cut off at 0:00 and played again, for ever.
      final point = PlayedPoint()
        ..see(_s(209))
        ..see(Duration.zero);
      expect(
        endedEarly(reached: Duration.zero, total: _s(210), margin: _margin),
        isTrue,
        reason: 'what the old code saw',
      );
      expect(
        endedEarly(reached: point.at, total: _s(210), margin: _margin),
        isFalse,
        reason: 'what the new code sees',
      );
    });
  });
}
