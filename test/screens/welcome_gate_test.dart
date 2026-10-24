import 'dart:io';

import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:swarved/content/labels.dart';
import 'package:swarved/content/words.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/screens/welcome/reveal_text.dart';
import 'package:swarved/screens/welcome/welcome_dots.dart';
import 'package:swarved/screens/welcome/welcome_gate.dart';
import 'package:swarved/screens/welcome/welcome_pages.dart';
import 'package:swarved/screens/welcome/welcome_screen.dart';
import 'package:swarved/services/song_playback.dart';
import 'package:swarved/services/tutorial_song_service.dart';
import 'package:swarved/services/welcome_service.dart';
import 'package:swarved/theme/colors.dart';
import 'package:swarved/widgets/swar_outlined_button.dart';
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

/// A welcome whose song has been prepared, as it is in the app: the file is
/// "copied" into a temporary folder and its tags say How Bad, by Asal.
Future<WelcomeService> _welcomeWithSong(
  WidgetTester tester,
  String json,
) async {
  final cache = Directory.systemTemp.createTempSync('welcome_gate_test');
  addTearDown(() => cache.deleteSync(recursive: true));
  final service = WelcomeService(
    loader: () async => json,
    songService: TutorialSongService(
      loadAsset: (_) async => Uint8List.fromList([1, 2, 3]),
      readTags: (_) => const SongTags(title: 'How Bad', artist: 'Asal'),
      cacheDirectory: () async => cache,
    ),
  );
  await tester.runAsync(() async {
    await service.load();
    await service.songReady;
  });
  return service;
}

/// A stand-in for the player: it only remembers what was pressed. Pressing
/// play puts a song on, like the real one.
class _FakePlayback extends ChangeNotifier implements SongPlayback {
  final started = <String>[];
  bool _on = false;
  bool playing = false;

  @override
  bool get hasSong => _on;

  @override
  bool isPlaying(Track track) => playing;

  @override
  void toggle(Track track) {
    started.add(track.title);
    _on = true;
    playing = !playing;
    notifyListeners();
  }
}

/// A player that never manages to start anything, to show that her press
/// still lets her go on.
class _DeadPlayback extends _FakePlayback {
  @override
  void toggle(Track track) {}
}

Widget _app(
  WelcomeService welcome, {
  bool reduceMotion = false,
  SongPlayback? playback,
}) {
  return ChangeNotifierProvider<WelcomeService>.value(
    value: welcome,
    child: MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
          ),
          child: WelcomeGate(
            playback: playback,
            child: const Scaffold(body: Text('the app')),
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

/// Taps Next [taps] times to reach the last step, then comes in. From the
/// first step of the four-step welcome that is three taps; with the song
/// step it is four from the first and three from the song.
Future<void> _comeIn(WidgetTester tester, {int taps = 3}) async {
  for (var i = 0; i < taps; i++) {
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

  group('The song step', () {
    /// The first Next: on to the song step.
    Future<_FakePlayback> toTheSong(
      WidgetTester tester, {
      bool reduceMotion = false,
      String json = '{}',
      _FakePlayback? player,
    }) async {
      _roomyScreen(tester);
      final welcome = await _welcomeWithSong(tester, json);
      final playback = player ?? _FakePlayback();
      await tester.pumpWidget(
        _app(welcome, reduceMotion: reduceMotion, playback: playback),
      );
      if (reduceMotion) {
        await tester.pump();
      } else {
        await _finishIntro(tester);
      }
      await _next(tester);
      // Let the last of the song step's lines finish arriving (about 1.3s
      // in all, and _next has given it 0.7s).
      await tester.pump(const Duration(milliseconds: 700));
      return playback;
    }

    Future<void> pressPlay(WidgetTester tester) async {
      await tester.tap(find.byTooltip(Labels.play));
      await tester.pump();
    }

    Finder nextFinder() =>
        find.widgetWithText(SwarOutlinedButton, Labels.welcomeNext);

    SwarOutlinedButton nextButton(WidgetTester tester) =>
        tester.widget<SwarOutlinedButton>(nextFinder());

    Color? nextColor(WidgetTester tester) => tester
        .widget<Text>(find.descendant(
          of: nextFinder(),
          matching: find.text(Labels.welcomeNext),
        ))
        .style
        ?.color;

    WelcomeDots dots(WidgetTester tester) =>
        tester.widget<WelcomeDots>(find.byType(WelcomeDots));

    testWidgets('comes second: his line, the song in a box, a few words',
        (tester) async {
      await toTheSong(tester);

      expect(find.text(Words.welcomeSongLine), findsOneWidget);
      expect(find.text(Words.welcomeSongText), findsOneWidget);
      expect(find.text('How Bad'), findsOneWidget);
      expect(find.text('Asal'), findsOneWidget);
      expect(find.byTooltip(Labels.play), findsOneWidget);
      // The story is the step after, not this one.
      expect(find.text(Words.welcomeStoryTitle), findsNothing);
    });

    testWidgets('the song sits in a box: title over artist, play on the right',
        (tester) async {
      await toTheSong(tester);

      final line = tester.getCenter(find.text(Words.welcomeSongLine));
      final title = tester.getCenter(find.text('How Bad'));
      final artist = tester.getCenter(find.text('Asal'));
      final play = tester.getCenter(find.byTooltip(Labels.play));
      final words = tester.getCenter(find.text(Words.welcomeSongText));

      expect(play.dx, greaterThan(title.dx), reason: 'play is on the right');
      expect(artist.dy, greaterThan(title.dy), reason: 'artist under title');
      expect(
        tester.getTopLeft(find.text('Asal')).dx,
        tester.getTopLeft(find.text('How Bad')).dx,
        reason: 'both start at the left edge of the box',
      );
      expect(line.dy, lessThan(title.dy), reason: 'his line is above');
      expect(words.dy, greaterThan(title.dy), reason: 'his words are below');
    });

    testWidgets('Next is locked until she presses play', (tester) async {
      await toTheSong(tester);

      expect(nextButton(tester).onPressed, isNull);
      expect(nextColor(tester), AppColors.textFaint);

      // Pressing it does nothing.
      await tester.tap(nextFinder());
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('How Bad'), findsOneWidget);
      expect(find.text(Words.welcomeStoryTitle), findsNothing);

      await pressPlay(tester);

      expect(nextButton(tester).onPressed, isNotNull);
      expect(nextColor(tester), AppColors.accent);
    });

    testWidgets('a pause does not lock it again', (tester) async {
      await toTheSong(tester);
      await pressPlay(tester);

      await tester.tap(find.byTooltip(Labels.pause));
      await tester.pump();

      expect(nextButton(tester).onPressed, isNotNull);
    });

    testWidgets('her press counts even if the song cannot start',
        (tester) async {
      await toTheSong(tester, player: _DeadPlayback());

      await pressPlay(tester);

      expect(nextButton(tester).onPressed, isNotNull);
    });

    testWidgets('it stays open when she goes back and on again',
        (tester) async {
      await toTheSong(tester);
      await pressPlay(tester);
      await _next(tester);
      expect(find.text(Words.welcomeStoryTitle), findsOneWidget);

      await tester.tap(find.byTooltip(Labels.welcomeBack));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('How Bad'), findsOneWidget);
      expect(nextButton(tester).onPressed, isNotNull);
    });

    testWidgets('Skip still leaves from here, without playing', (tester) async {
      await toTheSong(tester);

      await tester.tap(find.text(Labels.welcomeSkip));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(WelcomeScreen), findsNothing);
      expect(find.text('the app'), findsOneWidget);
    });

    testWidgets('the other steps are never locked', (tester) async {
      await toTheSong(tester);
      await pressPlay(tester);
      await _next(tester); // story
      expect(nextButton(tester).onPressed, isNotNull);
      await _next(tester); // notes
      expect(nextButton(tester).onPressed, isNotNull);
    });

    testWidgets('uses his own words when the welcome file has them',
        (tester) async {
      await toTheSong(
        tester,
        json: '{"songLine": "Press play, my love.", '
            '"songText": "Hold on to this one."}',
      );

      expect(find.text('Press play, my love.'), findsOneWidget);
      expect(find.text('Hold on to this one.'), findsOneWidget);
      expect(find.text(Words.welcomeSongLine), findsNothing);
      expect(find.text(Words.welcomeSongText), findsNothing);
    });

    testWidgets('the journey is five steps with a song, four without',
        (tester) async {
      _roomyScreen(tester);
      final withSong = await _welcomeWithSong(tester, '{}');
      await tester.pumpWidget(_app(withSong, playback: _FakePlayback()));
      await _finishIntro(tester);
      expect(dots(tester).count, 5);
    });

    testWidgets('no song to offer leaves the four steps', (tester) async {
      _roomyScreen(tester);
      final noSong = await _welcome(tester, '{}');
      await tester.pumpWidget(_app(noSong, playback: _FakePlayback()));
      await _finishIntro(tester);

      expect(dots(tester).count, 4);
      await _next(tester);
      expect(find.text(Words.welcomeStoryTitle), findsOneWidget);
    });

    testWidgets('no player to start it leaves the four steps', (tester) async {
      _roomyScreen(tester);
      final withSong = await _welcomeWithSong(tester, '{}');
      await tester.pumpWidget(_app(withSong));
      await _finishIntro(tester);

      expect(dots(tester).count, 4);
      await _next(tester);
      expect(find.text(Words.welcomeStoryTitle), findsOneWidget);
    });

    testWidgets('play starts the song and the button turns to pause',
        (tester) async {
      final playback = await toTheSong(tester);

      await pressPlay(tester);

      expect(playback.started, ['How Bad']);
      expect(find.byTooltip(Labels.pause), findsOneWidget);
      expect(find.byTooltip(Labels.play), findsNothing);

      // Pressed again, it pauses.
      await tester.tap(find.byTooltip(Labels.pause));
      await tester.pump();
      expect(playback.playing, isFalse);
      expect(find.byTooltip(Labels.play), findsOneWidget);
    });

    testWidgets('the song carries on while she reads on', (tester) async {
      final playback = await toTheSong(tester);
      await pressPlay(tester);

      await _next(tester);
      expect(find.text(Words.welcomeStoryTitle), findsOneWidget);
      expect(playback.playing, isTrue);

      await _next(tester);
      expect(find.text(Words.welcomeNotesTitle), findsOneWidget);
      expect(playback.playing, isTrue);
      // Only her one press ever reached the player.
      expect(playback.started, ['How Bad']);
    });

    testWidgets('Come in is still the fifth step', (tester) async {
      await toTheSong(tester);
      await pressPlay(tester);

      // Story, notes, tour: three more taps, and then Come in.
      await _comeIn(tester);

      expect(find.byType(WelcomeScreen), findsNothing);
      expect(find.text('the app'), findsOneWidget);
    });

    testWidgets('with reduced motion the song step is there at once',
        (tester) async {
      await toTheSong(tester, reduceMotion: true);

      expect(find.text(Words.welcomeSongLine), findsOneWidget);
      expect(find.text('How Bad'), findsOneWidget);
      expect(find.text('Asal'), findsOneWidget);
      expect(find.byTooltip(Labels.play), findsOneWidget);
    });

    testWidgets('a song with no artist shows its title and the button',
        (tester) async {
      _roomyScreen(tester);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WelcomeSongPage(
            line: 'A line.',
            text: 'Some words.',
            track: Track(
              filePath: '/cache/song.mp3',
              title: 'Untitled',
              artist: '',
              album: '',
              duration: Duration.zero,
              folder: 'Our first song',
            ),
            playback: _FakePlayback(),
            instant: true,
          ),
        ),
      ));

      // His line, the title and his words: no empty artist line.
      expect(find.byType(Text), findsNWidgets(3));
      expect(find.text('Untitled'), findsOneWidget);
      expect(find.byTooltip(Labels.play), findsOneWidget);
    });

    testWidgets('the page says when play is pressed', (tester) async {
      _roomyScreen(tester);
      var pressed = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WelcomeSongPage(
            line: 'A line.',
            text: 'Some words.',
            track: Track(
              filePath: '/cache/song.mp3',
              title: 'Untitled',
              artist: 'Someone',
              album: '',
              duration: Duration.zero,
              folder: 'Our first song',
            ),
            playback: _FakePlayback(),
            onPlayed: () => pressed++,
            instant: true,
          ),
        ),
      ));

      await tester.tap(find.byTooltip(Labels.play));
      await tester.pump();

      expect(pressed, 1);
    });
  });

  group('The tour after the song step', () {
    /// Pressing play (or skipping instead, since Next is locked until she
    /// has played), coming in, and waiting out the opening, so the tour is
    /// on its first stop.
    Future<void> toTheTour(WidgetTester tester, {required bool play}) async {
      _roomyScreen(tester);
      final welcome = await _welcomeWithSong(tester, '{}');
      await tester.pumpWidget(_app(welcome, playback: _FakePlayback()));
      await _finishIntro(tester);
      await _next(tester);
      if (play) {
        await tester.tap(find.byTooltip(Labels.play));
        await tester.pump();
        await _comeIn(tester);
      } else {
        await tester.tap(find.text(Labels.welcomeSkip));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
      }
      await tester.pump(const Duration(seconds: 15));
      await tester.pump(const Duration(milliseconds: 700));
    }

    Future<void> nextStop(WidgetTester tester) async {
      await tester.tap(find.text(Labels.welcomeNext));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
    }

    testWidgets('does not ask her to press play', (tester) async {
      await toTheTour(tester, play: true);

      expect(find.byType(TutorialSpotlight), findsOneWidget);
      expect(find.text(Words.tutorialFolders), findsOneWidget);
    });

    testWidgets('stops at the mini player when she started the song',
        (tester) async {
      await toTheTour(tester, play: true);

      await nextStop(tester);
      await nextStop(tester);

      expect(find.text(Words.tutorialPlayer), findsOneWidget);
    });

    testWidgets('leaves the mini player out when she skipped the song',
        (tester) async {
      await toTheTour(tester, play: false);

      await nextStop(tester);
      await nextStop(tester);

      expect(find.text(Words.tutorialPlayer), findsNothing);
      expect(find.text(Words.tutorialSearch), findsOneWidget);
    });
  });

  group('The notes arrows', () {
    const notes = '{"notes": ["One.", "Two.", "Three."]}';

    Future<void> toTheNotes(
      WidgetTester tester, {
      bool reduceMotion = false,
    }) async {
      _roomyScreen(tester);
      final welcome = await _welcome(tester, notes);
      await tester.pumpWidget(_app(welcome, reduceMotion: reduceMotion));
      if (reduceMotion) {
        await tester.pump();
      } else {
        await _finishIntro(tester);
      }
      await _next(tester);
      await _next(tester);
    }

    IconButton arrow(WidgetTester tester, String label) {
      return tester.widget<IconButton>(find.ancestor(
        of: find.byTooltip(label),
        matching: find.byType(IconButton),
      ));
    }

    Future<void> press(WidgetTester tester, String label) async {
      await tester.tap(find.byTooltip(label));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
    }

    testWidgets('move between the notes, either way', (tester) async {
      await toTheNotes(tester);
      expect(find.text('1 / 3'), findsOneWidget);

      await press(tester, Labels.welcomeNoteNext);
      expect(find.text('2 / 3'), findsOneWidget);

      await press(tester, Labels.welcomeNoteNext);
      expect(find.text('3 / 3'), findsOneWidget);

      await press(tester, Labels.welcomeNotePrevious);
      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('are dead where there is nowhere to go', (tester) async {
      await toTheNotes(tester);

      expect(arrow(tester, Labels.welcomeNotePrevious).onPressed, isNull);
      expect(arrow(tester, Labels.welcomeNoteNext).onPressed, isNotNull);

      // Pressing the dead one does nothing.
      await press(tester, Labels.welcomeNotePrevious);
      expect(find.text('1 / 3'), findsOneWidget);

      await press(tester, Labels.welcomeNoteNext);
      await press(tester, Labels.welcomeNoteNext);

      expect(arrow(tester, Labels.welcomeNoteNext).onPressed, isNull);
      expect(arrow(tester, Labels.welcomeNotePrevious).onPressed, isNotNull);
    });

    testWidgets('follow a swipe too', (tester) async {
      await toTheNotes(tester);

      await tester.drag(find.byType(PageView), const Offset(-250, 0));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('2 / 3'), findsOneWidget);
      expect(arrow(tester, Labels.welcomeNotePrevious).onPressed, isNotNull);
    });

    testWidgets('with reduced motion they jump straight there', (tester) async {
      await toTheNotes(tester, reduceMotion: true);

      await tester.tap(find.byTooltip(Labels.welcomeNoteNext));
      await tester.pump();

      expect(find.text('2 / 3'), findsOneWidget);
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

    testWidgets(
        'with reduced motion the opening is skipped but the tour is not',
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
