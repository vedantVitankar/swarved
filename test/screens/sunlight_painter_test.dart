import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/screens/welcome/sunlight_painter.dart';

Widget _sun(SunlightPainter painter) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: CustomPaint(painter: painter, size: const Size(96, 96)),
    ),
  );
}

void main() {
  group('SunlightPainter', () {
    test('one ambient loop turns the ring by a whole pattern of flares', () {
      expect(SunlightPainter.rayCount % SunlightPainter.patternLength, 0);
      expect(
        SunlightPainter.loopTurn,
        closeTo(
          SunlightPainter.patternLength * 2 * math.pi / SunlightPainter.rayCount,
          1e-9,
        ),
      );
    });

    test('the long flare is about nine tenths of the sun across, the short '
        'one clearly shorter', () {
      expect(SunlightPainter.longArc, 0.9);
      expect(SunlightPainter.shortArc, inInclusiveRange(0.4, 0.7));
    });

    testWidgets('paints at every stage without a problem', (tester) async {
      for (final (bloom, rays) in [(0.0, 0.0), (1.0, 0.0), (0.5, 0.5), (1.0, 1.0)]) {
        await tester.pumpWidget(_sun(SunlightPainter(
          bloom: bloom,
          rays: rays,
          breath: 0.5,
          rotation: 1.2,
        )));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('paints turned all the way round the loop', (tester) async {
      for (final fraction in [0.0, 0.25, 0.5, 1.0]) {
        await tester.pumpWidget(_sun(SunlightPainter(
          bloom: 1,
          rays: 1,
          breath: 0,
          rotation: fraction * SunlightPainter.loopTurn,
        )));
        expect(tester.takeException(), isNull);
      }
    });

    test('repaints only when something it draws has changed', () {
      const painter = SunlightPainter(
        bloom: 1,
        rays: 1,
        breath: 0,
        rotation: 0.3,
      );
      const same = SunlightPainter(
        bloom: 1,
        rays: 1,
        breath: 0,
        rotation: 0.3,
      );
      const turned = SunlightPainter(
        bloom: 1,
        rays: 1,
        breath: 0,
        rotation: 0.4,
      );

      expect(painter.shouldRepaint(same), isFalse);
      expect(painter.shouldRepaint(turned), isTrue);
    });
  });
}
