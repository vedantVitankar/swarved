import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:swarved/content/labels.dart';
import 'package:swarved/content/words.dart';
import 'package:swarved/screens/welcome/reveal_text.dart';
import 'package:swarved/screens/welcome/welcome_gate.dart';
import 'package:swarved/screens/welcome/welcome_screen.dart';
import 'package:swarved/services/welcome_service.dart';
import 'package:swarved/tutorial/tutorial_intro.dart';
import 'package:swarved/tutorial/tutorial_spotlight.dart';

/// Fonts come from the bundled files, as in the app.
void _useBundledFonts() => GoogleFonts.config.allowRuntimeFetching = false;

/// Tests draw text in wide square letters until real fonts load, so give the
/// screen room: nothing should depend on how tall the words come out.
void _roomyScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<WelcomeService> _welcome(WidgetTester tester, String json) async {
  final service = WelcomeService(loader: () async => json);
  await tester.runAsync(service.load);
  return service;
}

Widget _app(WelcomeService welcome, {bool reduceMotion = false}) {
  return Provider<WelcomeService>.value(
    value: welcome,
    child: MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
          ),
          child: const WelcomeGate(
            child: Scaffold(body: Text('the app')),
          ),
        ),
      ),
    ),
  );
}

/// The words the welcome is showing, one entry per piece of text. Each is
/// drawn piece by piece, so there is no single Text to look for.
List<String> _revealed(WidgetTester tester) => [
      for (final reveal in tester.widgetList<RevealText>(
        find.byType(RevealText),
      ))
        reveal.text,
    ];

/// The intro takes 4.6 seconds. The ambient loop never stops, so these tests
/// move time forward by hand instead of waiting for things to settle.
Future<void> _finishIntro(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 6));
}

/// Taps Next and waits for the page change to finish.
Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.text(Labels.welcomeNext));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

/// Walks through the story, the notes and the tour, then comes in.
Future<void> _comeIn(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await _next(tester);
  }
  await tester.tap(find.text(Labels.welcomeEnter));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  setUpAll(_useBundledFonts);

  group('WelcomeGate', () {
    testWidgets('shows the welcome over the app, with the default words',
        (tester) async {
      _roomyScreen(tester);
      final welcome = await _welcome(tester, '{}');
      await tester.pumpWidget(_app(welcome));
      await _finishIntro(tester);

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(_revealed(tester), [
        Words.swarnima,
        Words.welcomeLine,
        Words.welcomeSignature,
      ]);
      expect(find.text(Labels.welcomeNext), findsOneWidget);
      // Coming in is the last step, not the first.
      expect(find.text(Labels.welcomeEnter), findsNothing);
    });

    testWidgets('his own line and signature take over from the defaults',
        (tester) async {
      _roomyScreen(tester);
      final welcome = await _welcome(
        tester,
        '{"line": "Stay a while.", "signature": "Yours"}',
      );
      await tester.pumpWidget(_app(welcome));
      await _finishIntro(tester);

      expect(_revealed(tester), [Words.swarnima, 'Stay a while.', 'Yours']);
    });

    testWidgets('Come in fades the welcome away and leaves the app',
        (tester) async {
      _roomyScreen(tester);
      final welcome = await _welcome(tester, '{}');
      await tester.pumpWidget(_app(welcome));
      await _finishIntro(tester);

      await _comeIn(tester);

      expect(find.byType(WelcomeScreen), findsNothing);
      expect(find.text('the app'), findsOneWidget);
    });

    testWidgets('a tap before the intro ends skips ahead, not in',
        (tester) async {
      _roomyScreen(tester);
      final welcome = await _welcome(tester, '{}');
      await tester.pumpWidget(_app(welcome));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Too early for the button: this tap only skips to the end.
      await tester.tapAt(const Offset(400, 300));
      await tester.pump();
      expect(find.byType(WelcomeScreen), findsOneWidget);

      // Now the button works.
      await _comeIn(tester);
      expect(find.byType(WelcomeScreen), findsNothing);
    });

    testWidgets('with reduced motion everything is there at once',
        (tester) async {
      _roomyScreen(tester);
      final welcome = await _welcome(tester, '{}');
      await tester.pumpWidget(_app(welcome, reduceMotion: true));
      await tester.pump();

      // No waiting for the intro: the buttons already work.
      await tester.tap(find.text(Labels.welcomeSkip));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(WelcomeScreen), findsNothing);
    });

    testWidgets('Skip leaves from the first step', (tester) async {
      _roomyScreen(tester);
      final welcome = await _welcome(tester, '{}');
      await tester.pumpWidget(_app(welcome));
      await _finishIntro(tester);

      await tester.tap(find.text(Labels.welcomeSkip));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(WelcomeScreen), findsNothing);
      expect(find.text('the app'), findsOneWidget);
    });
  });

  group('The welcome journey', () {
    testWidgets('the second step tells why he made it', (tester) async {
      _roomyScreen(tester);
      final welcome = await _welcome(tester, '{}');
      await tester.pumpWidget(_app(welcome));
      await _finishIntro(tester);

      await _next(tester);

      expect(find.text(Words.welcomeStoryTitle), findsOneWidget);
      for (final paragraph in Words.welcomeStory) {
        expect(find.text(paragraph), findsOneWidget);
      }
      expect(find.text(Words.welcomeSignature), findsOneWidget);
    });

    testWidgets('his own story takes over from the default', (tester) async {
      _roomyScreen(tester);
      final welcome = await _welcome(
        tester,
        '{"story": ["Once upon a song."]}',
      );
      await tester.pumpWidget(_app(welcome));
      await _finishIntro(tester);

      await _next(tester);

      expect(find.text('Once upon a song.'), findsOneWidget);
      expect(find.text(Words.welcomeStory.first), findsNothing);
    });

    testWidgets('the third step shows his notes, one at a time',
        (tester) async {
      _roomyScreen(tester);
      final welcome = await _welcome(
        tester,
        '{"notes": ["One.", "Two.", '
        '{"label": "Gold", "note": "Three."}]}',
      );
      await tester.pumpWidget(_app(welcome));
      await _finishIntro(tester);

      await _next(tester);
      await _next(tester);

      expect(find.text(Words.welcomeNotesTitle), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);
      expect(find.text('One.'), findsOneWidget);
      expect(find.text(Words.welcomeNoteLabel), findsWidgets);

      // Swiping the card moves on to the next note.
      await tester.drag(find.byType(PageView), const Offset(-250, 0));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('the default notes appear when he wrote none', (tester) async {
      _roomyScreen(tester);
      final welcome = await _welcome(tester, '{}');
      await tester.pumpWidget(_app(welcome));
      await _finishIntro(tester);

      await _next(tester);
      await _next(tester);

      expect(find.text('1 / ${Words.welcomeNotes.length}'), findsOneWidget);
      expect(find.text(Words.welcomeNotes.first), findsOneWidget);
    });

    testWidgets('the last step tours the four tabs and offers Come in',
        (tester) async {
      _roomyScreen(tester);
      final welcome = await _welcome(tester, '{}');
      await tester.pumpWidget(_app(welcome));
      await _finishIntro(tester);

      for (var i = 0; i < 3; i++) {
        await _next(tester);
      }

      expect(find.text(Words.welcomeTourTitle), findsOneWidget);
      for (final tab in [
        Labels.navHome,
        Labels.navSearch,
        Labels.navLibrary,
        Labels.navUs,
      ]) {
        expect(find.text(tab), findsOneWidget);
      }
      expect(find.text(Labels.welcomeEnter), findsOneWidget);
      expect(find.text(Labels.welcomeNext), findsNothing);
      // There is nothing left to skip on the last step.
      expect(find.text(Labels.welcomeSkip), findsNothing);
    });

    testWidgets('Back returns to the step before', (tester) async {
      _roomyScreen(tester);
      final welcome = await _welcome(tester, '{}');
      await tester.pumpWidget(_app(welcome));
      await _finishIntro(tester);

      // No way back from the first step.
      expect(find.byTooltip(Labels.welcomeBack), findsNothing);

      await _next(tester);
      expect(find.text(Words.welcomeStoryTitle), findsOneWidget);

      await tester.tap(find.byTooltip(Labels.welcomeBack));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(_revealed(tester), [
        Words.swarnima,
        Words.welcomeLine,
        Words.welcomeSignature,
      ]);
    });

    testWidgets('with reduced motion every step is there at once',
        (tester) async {
      _roomyScreen(tester);
      final welcome = await _welcome(tester, '{}');
      await tester.pumpWidget(_app(welcome, reduceMotion: true));
      await tester.pump();

      await _next(tester);

      expect(find.text(Words.welcomeStory.first), findsOneWidget);

      // Two more Next taps, then Come in.
      await _next(tester);
      await _next(tester);
      await tester.tap(find.text(Labels.welcomeEnter));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(WelcomeScreen), findsNothing);
    });
  });

  group('The intro after the welcome', () {
    testWidgets('waits behind the welcome, then runs, then tours',
        (tester) async {
      _roomyScreen(tester);
      final welcome = await _welcome(tester, '{}');
      await tester.pumpWidget(_app(welcome));
      await _finishIntro(tester);

      // Nothing has started yet, but it is waiting underneath.
      expect(find.byType(TutorialIntro), findsOneWidget);

      await _comeIn(tester);
      expect(find.byType(WelcomeScreen), findsNothing);
      expect(find.byType(TutorialIntro), findsOneWidget);

      // The opening ends and the tour takes over.
      await tester.pump(const Duration(seconds: 15));
      expect(find.byType(TutorialIntro), findsNothing);
      expect(find.byType(TutorialSpotlight), findsOneWidget);
      expect(find.text('the app'), findsOneWidget);

      // Skipping the tour hands the app back.
      await tester.tap(find.text(Labels.welcomeSkip));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(TutorialSpotlight), findsNothing);
      expect(find.text('the app'), findsOneWidget);
    });

    testWidgets('with reduced motion the opening is skipped but the tour is not',
        (tester) async {
      _roomyScreen(tester);
      final welcome = await _welcome(tester, '{}');
      await tester.pumpWidget(_app(welcome, reduceMotion: true));
      await tester.pump();

      await tester.tap(find.text(Labels.welcomeSkip));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(WelcomeScreen), findsNothing);
      // No opening to wait for, but the tour is still there.
      expect(find.byType(TutorialIntro), findsNothing);
      expect(find.byType(TutorialSpotlight), findsOneWidget);
    });
  });
}
