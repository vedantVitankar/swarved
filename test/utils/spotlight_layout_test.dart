import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/utils/spotlight_layout.dart';

void main() {
  const screen = Size(400, 800);

  group('SpotlightLayout.hole', () {
    test('is a little larger than the lit part', () {
      const target = Rect.fromLTWH(100, 200, 200, 60);

      final hole = SpotlightLayout.hole(target, screen);

      expect(hole, target.inflate(SpotlightLayout.padding));
    });

    test('never reaches past the edges of the screen', () {
      const target = Rect.fromLTWH(0, 0, 400, 800);

      final hole = SpotlightLayout.hole(target, screen);

      expect(hole, const Rect.fromLTWH(0, 0, 400, 800));
    });

    test('a part hanging off the bottom is cut at the screen', () {
      const target = Rect.fromLTWH(20, 760, 100, 100);

      final hole = SpotlightLayout.hole(target, screen);

      expect(hole.bottom, 800);
      expect(hole.top, 752);
    });

    test('a part entirely off screen collapses instead of inverting', () {
      const target = Rect.fromLTWH(20, 2000, 100, 40);

      final hole = SpotlightLayout.hole(target, screen);

      expect(hole.width, greaterThanOrEqualTo(0));
      expect(hole.height, greaterThanOrEqualTo(0));
    });
  });

  group('SpotlightLayout.captionAbove', () {
    test('goes above a part low on the screen', () {
      const hole = Rect.fromLTWH(0, 700, 100, 80);

      expect(SpotlightLayout.captionAbove(hole, screen), isTrue);
    });

    test('goes below a part high on the screen', () {
      const hole = Rect.fromLTWH(0, 40, 100, 80);

      expect(SpotlightLayout.captionAbove(hole, screen), isFalse);
    });

    test('goes below when there is exactly as much room either way', () {
      const hole = Rect.fromLTWH(0, 350, 100, 100);

      expect(SpotlightLayout.captionAbove(hole, screen), isFalse);
    });
  });
}
