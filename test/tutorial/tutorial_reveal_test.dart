import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/models/tutorial_song.dart';
import 'package:swarved/tutorial/tutorial_controller.dart';
import 'package:swarved/tutorial/tutorial_reveal.dart';

/// No MaterialApp, so the only fade in the tree is the reveal's own.
Widget _host(
  TutorialController? c, {
  int order = 0,
  TutorialPart part = TutorialPart.rest,
}) {
  final child = Directionality(
    textDirection: TextDirection.ltr,
    child: TutorialReveal(
      part: part,
      order: order,
      child: const Text('hello'),
    ),
  );
  return c == null ? child : TutorialScope(controller: c, child: child);
}

double _opacity(WidgetTester tester) =>
    tester.widget<FadeTransition>(find.byType(FadeTransition)).opacity.value;

TutorialController _blank() => TutorialController(stage: TutorialStage.blank);

void main() {
  group('TutorialReveal', () {
    testWidgets('with no intro in the tree the child is simply there',
        (tester) async {
      await tester.pumpWidget(_host(null));

      expect(_opacity(tester), 1);
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('with the intro off the child is simply there',
        (tester) async {
      await tester.pumpWidget(_host(TutorialController()));

      expect(_opacity(tester), 1);
    });

    testWidgets('is invisible but laid out until the reveal', (tester) async {
      final c = _blank();
      await tester.pumpWidget(_host(c));

      expect(_opacity(tester), 0);
      // Still in the tree, so Home keeps its shape while blank.
      expect(find.text('hello'), findsOneWidget);

      c
        ..start()
        ..glide();
      await tester.pump();
      expect(_opacity(tester), 0);
    });

    testWidgets('fades in when the reveal begins', (tester) async {
      final c = _blank();
      await tester.pumpWidget(_host(c));

      c
        ..start()
        ..glide()
        ..reveal();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_opacity(tester), greaterThan(0.3));

      await tester.pump(const Duration(seconds: 3));
      expect(_opacity(tester), 1);
    });

    testWidgets('a later block waits for its turn', (tester) async {
      final c = _blank();
      await tester.pumpWidget(_host(c, order: 4));

      c
        ..start()
        ..glide()
        ..reveal();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_opacity(tester), 0);

      await tester.pump(const Duration(seconds: 3));
      expect(_opacity(tester), 1);
    });

    testWidgets('built after the reveal it is simply there', (tester) async {
      final c = _blank();
      c
        ..start()
        ..glide()
        ..reveal()
        ..finish();

      await tester.pumpWidget(_host(c, order: 3));

      expect(_opacity(tester), 1);
    });
  });

  group('TutorialReveal for the home note', () {
    testWidgets('ignores the reveal and waits for the intro to finish',
        (tester) async {
      final c = _blank();
      await tester.pumpWidget(_host(c, part: TutorialPart.note));

      c
        ..start()
        ..glide()
        ..reveal();
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(_opacity(tester), 0);

      c.finish();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(_opacity(tester), inExclusiveRange(0, 1));

      await tester.pump(const Duration(seconds: 2));
      expect(_opacity(tester), 1);
    });

    testWidgets('waits for Home to be on screen', (tester) async {
      final c = _blank();
      c.setHomeVisible(false);
      await tester.pumpWidget(_host(c, part: TutorialPart.note));

      c
        ..start()
        ..glide()
        ..reveal()
        ..finish();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(_opacity(tester), 0);

      c.setHomeVisible(true);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(_opacity(tester), 1);
    });
  });

  group('TutorialReveal when the song comes first', () {
    final song = TutorialSong(
      track: Track(
        filePath: '/cache/song.mp3',
        title: 'How Bad',
        artist: 'Asal',
        album: '',
        duration: Duration.zero,
        folder: 'Our first song',
      ),
    );

    TutorialController touring() => TutorialController(
          stage: TutorialStage.blank,
          tour: true,
        )
          ..start(song: song)
          ..glide()
          ..reveal()
          ..finish();

    testWidgets('the song shows but the rest waits for her to press play',
        (tester) async {
      final c = touring();
      await tester.pumpWidget(Column(
        children: [
          _host(c, part: TutorialPart.song),
          _host(c, part: TutorialPart.rest),
        ],
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      final fades = tester
          .widgetList<FadeTransition>(find.byType(FadeTransition))
          .map((fade) => fade.opacity.value)
          .toList();
      expect(fades, [1.0, 0.0]);
    });

    testWidgets('the rest fades in once play has been pressed',
        (tester) async {
      final c = TutorialController(stage: TutorialStage.blank, tour: true);
      await tester.pumpWidget(_host(c, part: TutorialPart.rest));
      c
        ..start(song: song)
        ..glide()
        ..reveal()
        ..finish();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(_opacity(tester), 0);

      c.advance();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(_opacity(tester), 1);
    });

    testWidgets('skipping on the play step brings the rest in too',
        (tester) async {
      final c = TutorialController(stage: TutorialStage.blank, tour: true);
      await tester.pumpWidget(_host(c, part: TutorialPart.rest));
      c
        ..start(song: song)
        ..glide()
        ..reveal()
        ..finish();
      await tester.pump();

      c.skip();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(_opacity(tester), 1);
    });
  });
}
