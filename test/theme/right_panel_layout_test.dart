import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/theme/responsive.dart';

void main() {
  group('right panel', () {
    test('opens at 1280 and not a pixel before', () {
      expect(Responsive.hasRightPanel(1279.9), isFalse);
      expect(Responsive.hasRightPanel(1280), isTrue);
      expect(Responsive.hasRightPanel(1920), isTrue);
    });

    test('is always inside the wide layout', () {
      expect(Responsive.of(Responsive.rightPanelFrom), ScreenClass.expanded);
    });

    test('the player and the page share one width', () {
      expect(Responsive.desktopPlayerMaxWidth, Responsive.contentMaxWidth);
    });
  });
}
