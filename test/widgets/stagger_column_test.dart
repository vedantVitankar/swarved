import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/widgets/stagger_column.dart';

double _opacityOf(WidgetTester tester, String text) {
  final fade = tester.widget<FadeTransition>(
    find.ancestor(
      of: find.text(text),
      matching: find.byType(FadeTransition),
    ),
  );
  return fade.opacity.value;
}

Widget _host({bool instant = false}) {
  // No MaterialApp: its page transitions bring fades of their own, and the
  // test wants to find only the ones from the column.
  return Directionality(
    textDirection: TextDirection.ltr,
    child: StaggerColumn(
      instant: instant,
      children: const [Text('first'), Text('second'), Text('third')],
    ),
  );
}

void main() {
  group('StaggerColumn', () {
    testWidgets('children arrive one after another', (tester) async {
      await tester.pumpWidget(_host());

      expect(_opacityOf(tester, 'first'), 0);
      expect(_opacityOf(tester, 'third'), 0);

      // Part way in: the first is well on its way, the last has not begun.
      await tester.pump(const Duration(milliseconds: 300));
      expect(_opacityOf(tester, 'first'), greaterThan(0.5));
      expect(_opacityOf(tester, 'third'), 0);

      // At the end every child is fully there.
      await tester.pump(const Duration(seconds: 2));
      expect(_opacityOf(tester, 'first'), 1);
      expect(_opacityOf(tester, 'second'), 1);
      expect(_opacityOf(tester, 'third'), 1);
    });

    testWidgets('instant shows everything from the first frame',
        (tester) async {
      await tester.pumpWidget(_host(instant: true));

      expect(_opacityOf(tester, 'first'), 1);
      expect(_opacityOf(tester, 'third'), 1);
    });

    testWidgets('leaves no timers or animations running once it is done',
        (tester) async {
      await tester.pumpWidget(_host());
      await tester.pump(const Duration(seconds: 3));

      // Settles at once: nothing is still animating.
      await tester.pumpAndSettle();
    });
  });
}
