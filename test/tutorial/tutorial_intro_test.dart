import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swarved/content/words.dart';
import 'package:swarved/tutorial/tutorial_controller.dart';
import 'package:swarved/tutorial/tutorial_intro.dart';
import 'package:swarved/utils/tutorial_timeline.dart';

/// A stand-in for Home: the real greeting where the intro should land, and
/// a button underneath that must not answer while the intro covers it.
Widget _host(
  TutorialController c, {
  bool reduceMotion = false,
  VoidCallback? onUnderneathTap,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: const Size(400, 800),
      disableAnimations: reduceMotion,
    ),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: TutorialScope(
        controller: c,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 72, 16, 0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(Words.greeting(DateTime.now()), key: c.greetingKey),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: onUnderneathTap,
                child: const Text('underneath'),
              ),
            ),
            TutorialIntro(controller: c),
          ],
        ),
      ),
    ),
  );
}

Finder _drawn(Finder within) =>
    find.descendant(of: within, matching: find.byType(Text));

String _typed(WidgetTester tester) {
  final text = tester.widget<Text>(
    _drawn(find.byType(TutorialIntro)),
  );
  return text.textSpan!.toPlainText().replaceAll('|', '');
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final letters = Words.greeting(DateTime.now()).length;

  group('TutorialIntro', () {
    testWidgets('draws nothing until the welcome hands over', (tester) async {
      final c = TutorialController(stage: TutorialStage.blank);
      await tester.pumpWidget(_host(c));
      await tester.pump(const Duration(seconds: 1));

      expect(c.stage, TutorialStage.blank);
      expect(_drawn(find.byType(TutorialIntro)), findsNothing);
    });

    testWidgets('types the greeting letter by letter', (tester) async {
      final c = TutorialController(stage: TutorialStage.blank);
      await tester.pumpWidget(_host(c));

      c.start();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final typed = _typed(tester);
      expect(c.stage, TutorialStage.typing);
      expect(typed.length, inInclusiveRange(1, letters - 1));
      expect(Words.greeting(DateTime.now()).startsWith(typed), isTrue);
    });

    testWidgets('glides, then reveals, then finishes, in order',
        (tester) async {
      final c = TutorialController(stage: TutorialStage.blank);
      await tester.pumpWidget(_host(c));

      c.start();
      await tester.pump();
      await tester.pump(
        TutorialTimeline.glideStart(letters) + const Duration(milliseconds: 50),
      );
      expect(c.stage, TutorialStage.gliding);
      // The whole greeting is there by the time it glides.
      expect(_typed(tester), Words.greeting(DateTime.now()));

      await tester.pump(TutorialTimeline.glide);
      expect(c.stage, TutorialStage.revealing);
      // Home's own greeting has taken over, so the overlay draws nothing.
      expect(_drawn(find.byType(TutorialIntro)), findsNothing);

      await tester.pump(
        TutorialTimeline.revealDuration + TutorialTimeline.settle,
      );
      expect(c.stage, TutorialStage.finished);
    });

    testWidgets('a very late frame still passes through every stage',
        (tester) async {
      final c = TutorialController(stage: TutorialStage.blank);
      final seen = <TutorialStage>[];
      c.addListener(() => seen.add(c.stage));
      await tester.pumpWidget(_host(c));

      c.start();
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));

      expect(c.stage, TutorialStage.finished);
      expect(seen, [
        TutorialStage.typing,
        TutorialStage.gliding,
        TutorialStage.revealing,
        TutorialStage.finished,
      ]);
    });

    testWidgets('takes every tap while it plays', (tester) async {
      final c = TutorialController(stage: TutorialStage.blank);
      var taps = 0;
      await tester.pumpWidget(_host(c, onUnderneathTap: () => taps++));

      c.start();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('underneath'), warnIfMissed: false);

      expect(taps, 0);
    });

    testWidgets('with reduced motion it hands over at once', (tester) async {
      final c = TutorialController(stage: TutorialStage.blank);
      await tester.pumpWidget(_host(c, reduceMotion: true));

      c.start();
      await tester.pump();

      expect(c.stage, TutorialStage.finished);
      expect(c.noteVisible, isTrue);
    });
  });
}
