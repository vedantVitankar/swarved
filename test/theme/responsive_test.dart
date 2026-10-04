import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/theme/responsive.dart';

void main() {
  group('Responsive.of', () {
    test('under 600 is compact', () {
      expect(Responsive.of(320), ScreenClass.compact);
      expect(Responsive.of(599.9), ScreenClass.compact);
    });

    test('600 up to 840 is medium', () {
      expect(Responsive.of(600), ScreenClass.medium);
      expect(Responsive.of(839.9), ScreenClass.medium);
    });

    test('840 and wider is expanded', () {
      expect(Responsive.of(840), ScreenClass.expanded);
      expect(Responsive.of(1920), ScreenClass.expanded);
    });
  });

  group('Responsive.textFactor', () {
    test('very small phones shrink text slightly', () {
      expect(Responsive.textFactor(320), 0.92);
      expect(Responsive.textFactor(339.9), 0.92);
    });

    test('normal phones keep text as designed', () {
      expect(Responsive.textFactor(340), 1.0);
      expect(Responsive.textFactor(411), 1.0);
    });

    test('larger screens grow text', () {
      expect(Responsive.textFactor(700), 1.06);
      expect(Responsive.textFactor(1280), 1.14);
    });
  });
}
