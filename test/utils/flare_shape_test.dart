import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/utils/flare_shape.dart';

const _bent = FlareShape(
  inner: 51,
  length: 99,
  halfWidth: 8.5,
  bend: 0.36,
  wave: 0.012,
);

void main() {
  group('FlareShape', () {
    test('the tip sits at the end of its length, bent clockwise', () {
      expect(_bent.tip.dx, closeTo(150, 0.001));
      // Positive is clockwise on screen, where y runs downwards.
      expect(_bent.tip.dy, closeTo(99 * 0.36, 0.001));
    });

    test('with no bend and no wave it points straight and sits level', () {
      const straight = FlareShape(
        inner: 51,
        length: 99,
        halfWidth: 8.5,
        bend: 0,
      );
      expect(straight.tip.dy, 0);

      final bounds = straight.path().getBounds();
      expect(bounds.top, closeTo(-bounds.bottom, 0.01));
    });

    test('starts at its base and reaches no further than its tip', () {
      final bounds = _bent.path().getBounds();

      expect(bounds.left, closeTo(51, 1.5));
      expect(bounds.right, closeTo(150, 0.5));
    });

    test('the body follows the bend, not the straight line to the tip', () {
      final path = _bent.path();

      // Halfway along, the middle has moved a quarter of the bend.
      final middle = Offset(51 + 99 * 0.5, 99 * 0.36 * 0.25);
      expect(path.contains(middle), isTrue);
      expect(path.contains(Offset(middle.dx, 0)), isFalse);
    });

    test('is wide near the base and narrow near the tip', () {
      final path = _bent.path();

      // Six steps to the side of the middle line, a tenth of the way up.
      final nearBase = Offset(51 + 9.9, 1.05 + 6);
      expect(path.contains(nearBase), isTrue);

      // The same six steps, nine tenths of the way up.
      final nearTip = Offset(51 + 89.1, 28.1 + 6);
      expect(path.contains(nearTip), isFalse);
    });

    test('the same numbers always give the same outline', () {
      expect(_bent.path().getBounds(), _bent.path().getBounds());
    });
  });

  group('FlareShape.withArc', () {
    test('is as long along its curve as it was asked to be', () {
      for (final bend in [0.0, 0.3, 0.62, 0.9]) {
        final shape = FlareShape.withArc(
          inner: 51,
          arc: 86.4,
          halfWidth: 8.5,
          bend: bend,
          wave: 0.03,
        );
        expect(shape.arcLength, closeTo(86.4, 0.2));
      }
    });

    test('the more it bends, the less far out it reaches', () {
      FlareShape bent(double bend) => FlareShape.withArc(
            inner: 51,
            arc: 86.4,
            halfWidth: 8.5,
            bend: bend,
          );

      expect(bent(0.3).reach, greaterThan(bent(0.6).reach));
      expect(bent(0.6).reach, greaterThan(bent(0.9).reach));
    });

    test('reach is the tip\'s distance from the centre', () {
      const shape = FlareShape(
        inner: 30,
        length: 40,
        halfWidth: 5,
        bend: 0,
      );

      expect(shape.reach, closeTo(70, 0.001));
    });
  });
}
