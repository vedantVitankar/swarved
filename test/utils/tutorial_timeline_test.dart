import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/utils/tutorial_timeline.dart';

void main() {
  group('TutorialTimeline typing', () {
    test('a short greeting still takes the minimum time', () {
      expect(TutorialTimeline.typing(3), TutorialTimeline.minTyping);
    });

    test('a long greeting takes a set time per letter', () {
      final letters = 40;
      expect(
        TutorialTimeline.typing(letters),
        TutorialTimeline.perLetter * letters,
      );
    });

    test('no letters at the start, all of them at the end', () {
      const letters = 20;
      final total = TutorialTimeline.typing(letters);

      expect(TutorialTimeline.lettersShown(Duration.zero, letters), 0);
      expect(TutorialTimeline.lettersShown(total, letters), letters);
      expect(
        TutorialTimeline.lettersShown(total + const Duration(seconds: 5), letters),
        letters,
      );
    });

    test('letters come steadily in between', () {
      const letters = 20;
      final half = TutorialTimeline.typing(letters) ~/ 2;

      expect(TutorialTimeline.lettersShown(half, letters), letters ~/ 2);
    });

    test('never shows more than there is, or fewer than none', () {
      expect(TutorialTimeline.lettersShown(const Duration(seconds: 1), 0), 0);
      expect(
        TutorialTimeline.lettersShown(const Duration(seconds: -1), 10),
        0,
      );
    });

    test('letters never go backwards as time passes', () {
      const letters = 25;
      var last = 0;
      for (var ms = 0; ms <= 4000; ms += 40) {
        final shown = TutorialTimeline.lettersShown(
          Duration(milliseconds: ms),
          letters,
        );
        expect(shown, greaterThanOrEqualTo(last));
        last = shown;
      }
    });
  });

  group('TutorialTimeline stages', () {
    test('typing, then a pause, then the glide, then the reveal', () {
      const letters = 20;

      expect(
        TutorialTimeline.glideStart(letters),
        TutorialTimeline.typing(letters) + TutorialTimeline.pause,
      );
      expect(
        TutorialTimeline.glideEnd(letters),
        TutorialTimeline.glideStart(letters) + TutorialTimeline.glide,
      );
      expect(
        TutorialTimeline.end(letters),
        TutorialTimeline.glideEnd(letters) +
            TutorialTimeline.revealDuration +
            TutorialTimeline.settle,
      );
    });

    test('the reveal lasts until the last block has arrived', () {
      expect(
        TutorialTimeline.revealDuration,
        TutorialTimeline.revealFade +
            TutorialTimeline.revealGap * (TutorialTimeline.revealBlocks - 1),
      );
    });
  });
}
