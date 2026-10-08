import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/theme/swar_glyphs.dart';
import 'package:swarved/widgets/swar_icon.dart';

/// Points along the real outline of [path], not its control points.
List<Offset> _outline(Path path) {
  final points = <Offset>[];
  for (final metric in path.computeMetrics()) {
    for (double d = 0; d < metric.length; d += 0.25) {
      final tangent = metric.getTangentForOffset(d);
      if (tangent != null) points.add(tangent.position);
    }
    final end = metric.getTangentForOffset(metric.length);
    if (end != null) points.add(end.position);
  }
  return points;
}

void main() {
  group('SwarGlyphs', () {
    test('every glyph has something to draw', () {
      for (final glyph in SwarGlyph.values) {
        final shape = SwarGlyphs.shapeOf(glyph);
        expect(shape.fill != null || shape.stroke != null, isTrue,
            reason: '$glyph is empty');
      }
    });

    test('every glyph stays inside the 24 grid', () {
      for (final glyph in SwarGlyph.values) {
        final shape = SwarGlyphs.shapeOf(glyph);
        for (final path in [shape.fill, shape.stroke]) {
          if (path == null) continue;
          final points = _outline(path);
          expect(points, isNotEmpty, reason: '$glyph has no outline');
          for (final p in points) {
            expect(p.dx, inInclusiveRange(0, SwarGlyphs.grid),
                reason: '$glyph at $p');
            expect(p.dy, inInclusiveRange(0, SwarGlyphs.grid),
                reason: '$glyph at $p');
          }
        }
      }
    });

    test('a glyph is built once and reused', () {
      expect(
        identical(SwarGlyphs.shapeOf(SwarGlyph.home),
            SwarGlyphs.shapeOf(SwarGlyph.home)),
        isTrue,
      );
    });
  });

  group('SwarIcon', () {
    testWidgets('draws every glyph at small and large sizes', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: [
              for (final glyph in SwarGlyph.values) ...[
                SwarIcon(glyph: glyph, size: 18),
                SwarIcon(glyph: glyph, size: 54),
              ],
            ],
          ),
        ),
      ));

      expect(find.byType(SwarIcon), findsNWidgets(SwarGlyph.values.length * 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('takes its size from the IconTheme when none is given',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: IconTheme(
          data: IconThemeData(size: 30, color: Colors.red),
          child: Center(child: SwarIcon(glyph: SwarGlyph.play)),
        ),
      ));

      expect(tester.getSize(find.byType(SwarIcon)), const Size(30, 30));
    });

    testWidgets('an explicit size wins over the IconTheme', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: IconTheme(
          data: IconThemeData(size: 30),
          child: Center(child: SwarIcon(glyph: SwarGlyph.play, size: 22)),
        ),
      ));

      expect(tester.getSize(find.byType(SwarIcon)), const Size(22, 22));
    });
  });
}
