import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:swarved/content/labels.dart';
import 'package:swarved/content/words.dart';
import 'package:swarved/screens/welcome/reveal_text.dart';
import 'package:swarved/screens/welcome/welcome_gate.dart';
import 'package:swarved/screens/welcome/welcome_screen.dart';
import 'package:swarved/services/content_service.dart';

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

Future<ContentService> _content(WidgetTester tester, String json) async {
  final service = ContentService(loader: () async => json);
  await tester.runAsync(service.load);
  return service;
}

Widget _app(ContentService content, {bool reduceMotion = false}) {
  return ChangeNotifierProvider<ContentService>.value(
    value: content,
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

Future<void> _comeIn(WidgetTester tester) async {
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
      final content = await _content(tester, '{}');
      await tester.pumpWidget(_app(content));
      await _finishIntro(tester);

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(_revealed(tester), [
        Words.swarnima,
        Words.welcomeLine,
        Words.welcomeSignature,
      ]);
      expect(find.text(Labels.welcomeEnter), findsOneWidget);
    });

    testWidgets('his own line and signature take over from the defaults',
        (tester) async {
      _roomyScreen(tester);
      final content = await _content(
        tester,
        '{"welcome": {"line": "Stay a while.", "signature": "Yours"}}',
      );
      await tester.pumpWidget(_app(content));
      await _finishIntro(tester);

      expect(_revealed(tester), [Words.swarnima, 'Stay a while.', 'Yours']);
    });

    testWidgets('Come in fades the welcome away and leaves the app',
        (tester) async {
      _roomyScreen(tester);
      final content = await _content(tester, '{}');
      await tester.pumpWidget(_app(content));
      await _finishIntro(tester);

      await _comeIn(tester);

      expect(find.byType(WelcomeScreen), findsNothing);
      expect(find.text('the app'), findsOneWidget);
    });

    testWidgets('a tap before the intro ends skips ahead, not in',
        (tester) async {
      _roomyScreen(tester);
      final content = await _content(tester, '{}');
      await tester.pumpWidget(_app(content));
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
      final content = await _content(tester, '{}');
      await tester.pumpWidget(_app(content, reduceMotion: true));
      await tester.pump();

      // No waiting for the intro: the button already works.
      await tester.tap(find.text(Labels.welcomeEnter));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(WelcomeScreen), findsNothing);
    });
  });
}
