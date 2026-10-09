import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/utils/welcome_timeline.dart';

void main() {
  group('TimeSpan.at', () {
    const span = TimeSpan(0.2, 0.6);

    test('is 0 before the span and 1 after it', () {
      expect(span.at(0), 0);
      expect(span.at(0.2), 0);
      expect(span.at(0.6), 1);
      expect(span.at(1), 1);
    });

    test('runs in a straight line inside the span', () {
      expect(span.at(0.4), closeTo(0.5, 1e-9));
      expect(span.at(0.3), closeTo(0.25, 1e-9));
    });
  });

  group('alphaFor', () {
    test('maps 0 to 1 onto 0 to 255 and stays inside it', () {
      expect(alphaFor(0), 0);
      expect(alphaFor(1), 255);
      expect(alphaFor(0.5), 128);
      expect(alphaFor(-3), 0);
      expect(alphaFor(7), 255);
    });
  });

  group('WelcomeTimeline', () {
    const intro = [
      WelcomeTimeline.sunRise,
      WelcomeTimeline.glowBloom,
      WelcomeTimeline.rays,
      WelcomeTimeline.dawn,
      WelcomeTimeline.motes,
      WelcomeTimeline.title,
      WelcomeTimeline.line,
      WelcomeTimeline.signature,
      WelcomeTimeline.button,
    ];
    const exit = [
      WelcomeTimeline.contentOut,
      WelcomeTimeline.sunSwell,
      WelcomeTimeline.overlayOut,
    ];

    test('every span starts before it ends and stays inside 0 to 1', () {
      for (final span in [...intro, ...exit]) {
        expect(span.start, greaterThanOrEqualTo(0));
        expect(span.end, lessThanOrEqualTo(1));
        expect(span.start, lessThan(span.end));
      }
    });

    test('the words come in order, and the button arrives last', () {
      expect(WelcomeTimeline.title.start, lessThan(WelcomeTimeline.line.start));
      expect(WelcomeTimeline.line.start,
          lessThan(WelcomeTimeline.signature.start));
      expect(WelcomeTimeline.signature.start,
          lessThan(WelcomeTimeline.button.start));
      expect(WelcomeTimeline.button.end, 1);
    });

    test('the screen is only gone once the sun has finished swelling', () {
      expect(WelcomeTimeline.overlayOut.end, 1);
      expect(WelcomeTimeline.overlayOut.start,
          lessThan(WelcomeTimeline.sunSwell.end));
    });

    test('reduced motion leaves quicker than the full exit', () {
      expect(
        WelcomeTimeline.reducedExitDuration.inMilliseconds,
        lessThan(WelcomeTimeline.exitDuration.inMilliseconds),
      );
    });
  });
}
