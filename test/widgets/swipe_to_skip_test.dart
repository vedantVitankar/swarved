import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/widgets/swipe_to_skip.dart';

SkipDirection _decide({
  double dx = 0,
  double velocity = 0,
  double width = 200,
  bool canPrevious = true,
  bool canNext = true,
}) {
  return SwipeToSkip.decide(
    dx: dx,
    velocity: velocity,
    width: width,
    canPrevious: canPrevious,
    canNext: canNext,
  );
}

void main() {
  group('SwipeToSkip.decide', () {
    test('a long drag left goes to the next song', () {
      expect(_decide(dx: -80), SkipDirection.next);
    });

    test('a long drag right goes to the previous song', () {
      expect(_decide(dx: 80), SkipDirection.previous);
    });

    test('a short, slow drag does nothing', () {
      expect(_decide(dx: -20), SkipDirection.none);
    });

    test('a quick flick counts even when it is short', () {
      expect(_decide(dx: -30, velocity: -900), SkipDirection.next);
    });

    test('a flick against the drag does not count', () {
      expect(_decide(dx: -30, velocity: 900), SkipDirection.none);
    });

    test('nothing happens when there is no next song', () {
      expect(_decide(dx: -80, canNext: false), SkipDirection.none);
    });

    test('nothing happens when there is no previous song', () {
      expect(_decide(dx: 80, canPrevious: false), SkipDirection.none);
    });

    test('a very narrow area still needs a real drag', () {
      expect(_decide(dx: -10, width: 40), SkipDirection.none);
      expect(_decide(dx: -30, width: 40), SkipDirection.next);
    });
  });
}
