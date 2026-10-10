import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/theme/swar_glyphs.dart';
import 'package:swarved/widgets/heart_button.dart';
import 'package:swarved/widgets/swar_icon.dart';

/// A tappable surface with the heart on it, like the mini player card.
Widget _surface({required VoidCallback onSurfaceTap, required Widget heart}) {
  return MaterialApp(
    home: Scaffold(
      body: Material(
        child: InkWell(
          onTap: onSurfaceTap,
          child: Center(child: heart),
        ),
      ),
    ),
  );
}

Finder _glyph(SwarGlyph glyph) =>
    find.byWidgetPredicate((w) => w is SwarIcon && w.glyph == glyph);

void main() {
  group('HeartButton', () {
    testWidgets('is a 40 by 40 target', (tester) async {
      await tester.pumpWidget(
          _surface(onSurfaceTap: () {}, heart: const HeartButton()));

      expect(tester.getSize(find.byType(HeartButton)), const Size(40, 40));
    });

    testWidgets('the dummy absorbs its taps instead of passing them on',
        (tester) async {
      var surfaceTaps = 0;
      await tester.pumpWidget(_surface(
        onSurfaceTap: () => surfaceTaps++,
        heart: const HeartButton(),
      ));

      await tester.tap(find.byType(HeartButton));
      expect(surfaceTaps, 0);

      // Sanity check: the surface does react when tapped elsewhere.
      await tester.tapAt(const Offset(20, 300));
      expect(surfaceTaps, 1);
    });

    testWidgets('calls onPressed when one is given', (tester) async {
      var pressed = 0;
      var surfaceTaps = 0;
      await tester.pumpWidget(_surface(
        onSurfaceTap: () => surfaceTaps++,
        heart: HeartButton(onPressed: () => pressed++),
      ));

      await tester.tap(find.byType(HeartButton));
      expect(pressed, 1);
      expect(surfaceTaps, 0);
    });

    testWidgets('calls onLongPress when it is held', (tester) async {
      var held = 0;
      var pressed = 0;
      await tester.pumpWidget(_surface(
        onSurfaceTap: () {},
        heart: HeartButton(
          onPressed: () => pressed++,
          onLongPress: () => held++,
        ),
      ));

      await tester.longPress(find.byType(HeartButton));

      expect(held, 1);
      expect(pressed, 0);
    });

    testWidgets('isFilled swaps the outline for the solid heart',
        (tester) async {
      await tester.pumpWidget(
          _surface(onSurfaceTap: () {}, heart: const HeartButton()));
      expect(_glyph(SwarGlyph.heart), findsOneWidget);
      expect(_glyph(SwarGlyph.heartFilled), findsNothing);

      await tester.pumpWidget(_surface(
          onSurfaceTap: () {}, heart: const HeartButton(isFilled: true)));
      expect(_glyph(SwarGlyph.heartFilled), findsOneWidget);
      expect(_glyph(SwarGlyph.heart), findsNothing);
    });
  });
}
