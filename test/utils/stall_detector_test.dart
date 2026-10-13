import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/utils/stall_detector.dart';

final _t0 = DateTime.utc(2026, 10, 14, 4, 30);

DateTime _at(int seconds) => _t0.add(Duration(seconds: seconds));

bool _look(
  StallDetector detector,
  int seconds, {
  required int position,
  bool expecting = true,
  bool buffering = false,
}) {
  return detector.tick(
    position: Duration(seconds: position),
    expectingSound: expecting,
    buffering: buffering,
    now: _at(seconds),
  );
}

void main() {
  group('StallDetector', () {
    test('a song that keeps moving is never a stall', () {
      final detector = StallDetector();

      for (var s = 0; s < 120; s += 2) {
        expect(_look(detector, s, position: s), isFalse);
      }
    });

    test('a song that stands still for the limit is a stall', () {
      final detector = StallDetector();

      expect(_look(detector, 0, position: 30), isFalse);
      expect(_look(detector, 2, position: 30), isFalse);
      expect(_look(detector, 6, position: 30), isFalse);
      expect(_look(detector, 8, position: 30), isTrue);
    });

    test('it says true once, then counts again from zero', () {
      final detector = StallDetector();
      _look(detector, 0, position: 30);

      expect(_look(detector, 8, position: 30), isTrue);
      expect(_look(detector, 10, position: 30), isFalse);
      expect(_look(detector, 15, position: 30), isFalse);
      expect(_look(detector, 16, position: 30), isTrue);
    });

    test('moving again clears it', () {
      final detector = StallDetector();
      _look(detector, 0, position: 30);
      _look(detector, 6, position: 30);

      expect(_look(detector, 7, position: 31), isFalse);
      expect(_look(detector, 13, position: 31), isFalse);
      expect(_look(detector, 15, position: 31), isTrue);
    });

    test('a pause is never a stall, however long', () {
      final detector = StallDetector();

      for (var s = 0; s < 120; s += 2) {
        expect(_look(detector, s, position: 30, expecting: false), isFalse);
      }
    });

    test('pausing and resuming starts the count again', () {
      final detector = StallDetector();
      _look(detector, 0, position: 30);
      _look(detector, 6, position: 30, expecting: false); // paused

      expect(_look(detector, 8, position: 30), isFalse); // counting anew
      expect(_look(detector, 15, position: 30), isFalse);
      expect(_look(detector, 16, position: 30), isTrue);
    });

    test('waiting for more of the song is allowed to take longer', () {
      final detector = StallDetector();
      _look(detector, 0, position: 30, buffering: true);

      expect(_look(detector, 10, position: 30, buffering: true), isFalse);
      expect(_look(detector, 24, position: 30, buffering: true), isFalse);
      expect(_look(detector, 25, position: 30, buffering: true), isTrue);
    });

    test('the limits can be changed', () {
      final detector = StallDetector(limit: const Duration(seconds: 3));
      _look(detector, 0, position: 5);

      expect(_look(detector, 2, position: 5), isFalse);
      expect(_look(detector, 3, position: 5), isTrue);
    });

    test('reset forgets what was seen', () {
      final detector = StallDetector();
      _look(detector, 0, position: 30);
      _look(detector, 7, position: 30);

      detector.reset();

      expect(_look(detector, 8, position: 30), isFalse);
      expect(_look(detector, 15, position: 30), isFalse);
      expect(_look(detector, 16, position: 30), isTrue);
    });
  });
}
