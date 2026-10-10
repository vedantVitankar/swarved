import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swarved/content/labels.dart';
import 'package:swarved/widgets/playlist_name_dialog.dart';

class _Answer {
  bool given = false;
  String? name;
}

Future<_Answer> _open(WidgetTester tester, {String initialName = ''}) async {
  final answer = _Answer();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                answer.name = await showPlaylistNameDialog(
                  context,
                  title: 'Name it',
                  confirmLabel: 'Save',
                  initialName: initialName,
                );
                answer.given = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return answer;
}

Finder get _save => find.widgetWithText(TextButton, 'Save');

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('showPlaylistNameDialog', () {
    testWidgets('answers the name as it will be kept', (tester) async {
      final answer = await _open(tester);

      await tester.enterText(find.byType(TextField), '  Slow   dances ');
      await tester.pump();
      await tester.tap(_save);
      await tester.pumpAndSettle();

      expect(answer.given, isTrue);
      expect(answer.name, 'Slow dances');
    });

    testWidgets('cannot be saved while the name is empty', (tester) async {
      await _open(tester);
      expect(tester.widget<TextButton>(_save).onPressed, isNull);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(tester.widget<TextButton>(_save).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Rainy');
      await tester.pump();
      expect(tester.widget<TextButton>(_save).onPressed, isNotNull);
    });

    testWidgets('Cancel answers nothing', (tester) async {
      final answer = await _open(tester);

      await tester.enterText(find.byType(TextField), 'Rainy');
      await tester.pump();
      await tester.tap(find.text(Labels.cancel));
      await tester.pumpAndSettle();

      expect(answer.given, isTrue);
      expect(answer.name, isNull);
    });

    testWidgets('starts with the name it is given, to rename', (tester) async {
      final answer = await _open(tester, initialName: 'Old name');
      expect(find.text('Old name'), findsOneWidget);
      expect(tester.widget<TextButton>(_save).onPressed, isNotNull);

      await tester.tap(_save);
      await tester.pumpAndSettle();
      expect(answer.name, 'Old name');
    });
  });
}
