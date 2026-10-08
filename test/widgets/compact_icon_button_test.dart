import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/theme/swar_glyphs.dart';
import 'package:swarved/widgets/compact_icon_button.dart';

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('CompactIconButton', () {
    testWidgets('is a 40 by 40 target by default', (tester) async {
      await tester.pumpWidget(_host(
        CompactIconButton(icon: SwarGlyph.close, onPressed: () {}),
      ));

      expect(
          tester.getSize(find.byType(CompactIconButton)), const Size(40, 40));
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(_host(
        CompactIconButton(icon: SwarGlyph.close, onPressed: () => pressed++),
      ));

      await tester.tap(find.byType(CompactIconButton));
      expect(pressed, 1);
    });

    testWidgets('names itself with a tooltip when one is given',
        (tester) async {
      await tester.pumpWidget(_host(
        CompactIconButton(
            icon: SwarGlyph.close, tooltip: 'Add', onPressed: () {}),
      ));

      expect(find.byTooltip('Add'), findsOneWidget);
    });

    testWidgets('adds no tooltip when none is given', (tester) async {
      await tester.pumpWidget(_host(
        CompactIconButton(icon: SwarGlyph.close, onPressed: () {}),
      ));

      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('a tooltip does not change the size', (tester) async {
      await tester.pumpWidget(_host(
        CompactIconButton(
            icon: SwarGlyph.close, tooltip: 'Add', onPressed: () {}),
      ));

      expect(
          tester.getSize(find.byType(CompactIconButton)), const Size(40, 40));
    });
  });
}
