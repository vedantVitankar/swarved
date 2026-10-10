import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swarved/content/labels.dart';
import 'package:swarved/content/words.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/models/tutorial_song.dart';
import 'package:swarved/tutorial/tutorial_controller.dart';
import 'package:swarved/tutorial/tutorial_spotlight.dart';
import 'package:swarved/tutorial/tutorial_step.dart';

final _song = TutorialSong(
  track: Track(
    filePath: '/cache/song.mp3',
    title: 'How Bad',
    artist: 'Asal',
    album: '',
    duration: Duration.zero,
    folder: 'Our first song',
  ),
);

void _phoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

TutorialController _touring({TutorialSong? song, bool addFolder = false}) {
  return TutorialController(stage: TutorialStage.blank, tour: true)
    ..start(song: song, addFolder: addFolder)
    ..glide()
    ..reveal()
    ..finish();
}

/// A page with a few lit-able parts, a button that must stay dead under the
/// dimming, and the spotlight on top.
Widget _host(
  TutorialController controller, {
  Map<String, String> captions = const {},
  Listenable? playback,
  bool Function()? songIsPlaying,
  bool Function()? foldersEmpty,
  Listenable? library,
  String? Function()? folderPath,
  VoidCallback? onFolderButtonTap,
  VoidCallback? onTargetTap,
  VoidCallback? onUnderneathTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: TutorialScope(
        controller: controller,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: 20,
              top: 100,
              width: 200,
              height: 60,
              child: GestureDetector(
                onTap: onTargetTap,
                child: Container(
                  key: controller.keyFor(TutorialStep.play),
                  color: Colors.pink,
                ),
              ),
            ),
            Positioned(
              left: 20,
              top: 300,
              width: 200,
              height: 60,
              child: Container(
                key: controller.keyFor(TutorialStep.folders),
                color: Colors.red,
              ),
            ),
            Positioned(
              left: 20,
              top: 400,
              width: 200,
              height: 60,
              child: GestureDetector(
                onTap: onFolderButtonTap,
                child: Container(
                  key: controller.keyFor(TutorialStep.addFolder),
                  color: Colors.orange,
                ),
              ),
            ),
            Positioned(
              left: 20,
              top: 600,
              width: 200,
              height: 60,
              child: GestureDetector(
                onTap: onUnderneathTap,
                child: const Text('underneath'),
              ),
            ),
            TutorialSpotlight(
              controller: controller,
              captions: captions,
              playback: playback,
              songIsPlaying: songIsPlaying,
              foldersEmpty: foldersEmpty,
              library: library,
              folderPath: folderPath,
            ),
          ],
        ),
      ),
    ),
  );
}

/// A stand-in for the library: which folder it reads, and the ways it
/// announces a change.
class _FakeLibrary extends ChangeNotifier {
  String? path;

  _FakeLibrary(this.path);

  void choose(String? folder) {
    path = folder;
    notifyListeners();
  }

  /// A change that has nothing to do with the folder, like a scan ticking.
  void announce() => notifyListeners();
}

Future<void> _settle(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 700));

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('TutorialSpotlight without a song', () {
    testWidgets('opens on the first step with its caption', (tester) async {
      _phoneScreen(tester);
      final c = _touring();
      await tester.pumpWidget(_host(c));
      await _settle(tester);

      expect(find.text(Words.tutorialFolders), findsOneWidget);
      expect(find.text(Labels.welcomeNext), findsOneWidget);
      expect(find.text(Labels.welcomeSkip), findsOneWidget);
    });

    testWidgets('Next walks every step, then Start listening ends it',
        (tester) async {
      _phoneScreen(tester);
      final c = _touring();
      await tester.pumpWidget(_host(c));
      await _settle(tester);

      final captions = [
        Words.tutorialFolders,
        Words.tutorialChips,
        Words.tutorialSearch,
        Words.tutorialLibrary,
        Words.tutorialUs,
      ];
      for (var i = 0; i < captions.length - 1; i++) {
        expect(find.text(captions[i]), findsOneWidget);
        await tester.tap(find.text(Labels.welcomeNext));
        await tester.pump();
        await _settle(tester);
      }

      expect(find.text(captions.last), findsOneWidget);
      expect(find.text(Labels.welcomeNext), findsNothing);
      expect(find.text(Words.tutorialDone), findsOneWidget);

      await tester.tap(find.text(Words.tutorialDone));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(c.stage, TutorialStage.finished);
    });

    testWidgets('Skip ends the tour from the first step', (tester) async {
      _phoneScreen(tester);
      final c = _touring();
      await tester.pumpWidget(_host(c));
      await _settle(tester);

      await tester.tap(find.text(Labels.welcomeSkip));
      await tester.pump();
      // It fades out first, then hands back.
      expect(c.stage, TutorialStage.touring);
      await tester.pump(const Duration(seconds: 1));

      expect(c.stage, TutorialStage.finished);
    });

    testWidgets('his own caption replaces the default', (tester) async {
      _phoneScreen(tester);
      final c = _touring();
      await tester.pumpWidget(_host(c, captions: {'folders': 'Mine, baby.'}));
      await _settle(tester);

      expect(find.text('Mine, baby.'), findsOneWidget);
      expect(find.text(Words.tutorialFolders), findsNothing);
    });

    testWidgets('with no folders the step says where they will be',
        (tester) async {
      _phoneScreen(tester);
      final c = _touring();
      await tester.pumpWidget(_host(c, foldersEmpty: () => true));
      await _settle(tester);

      expect(find.text(Words.tutorialFoldersEmpty), findsOneWidget);
    });

    testWidgets('takes every tap while the screen is dimmed', (tester) async {
      _phoneScreen(tester);
      var underneath = 0;
      final c = _touring();
      await tester.pumpWidget(_host(c, onUnderneathTap: () => underneath++));
      await _settle(tester);

      await tester.tap(find.text('underneath'), warnIfMissed: false);

      expect(underneath, 0);
    });

    testWidgets('a lit part that cannot be found still shows its words',
        (tester) async {
      _phoneScreen(tester);
      final c = _touring();
      // Skip ahead to a step nothing in the host carries a key for.
      await tester.pumpWidget(_host(c));
      await _settle(tester);
      c.advance();
      await tester.pump();
      await _settle(tester);

      expect(find.text(Words.tutorialChips), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('back skips the tour instead of getting stuck',
        (tester) async {
      _phoneScreen(tester);
      final c = _touring();
      await tester.pumpWidget(_host(c));
      await _settle(tester);

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(c.stage, TutorialStage.finished);
    });
  });

  group('TutorialSpotlight with the song', () {
    testWidgets('asks her to press play, with no Next to press',
        (tester) async {
      _phoneScreen(tester);
      final c = _touring(song: _song);
      await tester.pumpWidget(_host(c));
      await _settle(tester);

      expect(find.text(Words.tutorialPlay), findsOneWidget);
      expect(find.text(Labels.welcomeNext), findsNothing);
      expect(find.text(Words.tutorialContinue), findsNothing);
    });

    testWidgets('only the lit card takes taps on the play step',
        (tester) async {
      _phoneScreen(tester);
      var card = 0;
      var underneath = 0;
      final c = _touring(song: _song);
      await tester.pumpWidget(_host(
        c,
        onTargetTap: () => card++,
        onUnderneathTap: () => underneath++,
      ));
      await _settle(tester);

      await tester.tapAt(const Offset(120, 130));
      await tester.tap(find.text('underneath'), warnIfMissed: false);

      expect(card, 1);
      expect(underneath, 0);
    });

    testWidgets('the song starting moves the tour on', (tester) async {
      _phoneScreen(tester);
      final playing = ValueNotifier<bool>(false);
      addTearDown(playing.dispose);
      final c = _touring(song: _song);
      await tester.pumpWidget(_host(
        c,
        playback: playing,
        songIsPlaying: () => playing.value,
      ));
      await _settle(tester);
      expect(c.step, TutorialStep.play);

      playing.value = true;
      await tester.pump();
      await _settle(tester);

      expect(c.step, TutorialStep.folders);
      expect(find.text(Words.tutorialFolders), findsOneWidget);
    });

    testWidgets('a song that is not playing does not move it on',
        (tester) async {
      _phoneScreen(tester);
      final playback = ValueNotifier<int>(0);
      addTearDown(playback.dispose);
      final c = _touring(song: _song);
      await tester.pumpWidget(_host(
        c,
        playback: playback,
        songIsPlaying: () => false,
      ));
      await _settle(tester);

      playback.value++;
      await tester.pump();

      expect(c.step, TutorialStep.play);
    });

    testWidgets('Continue appears if the song never starts', (tester) async {
      _phoneScreen(tester);
      final c = _touring(song: _song);
      await tester.pumpWidget(_host(c));
      await _settle(tester);
      expect(find.text(Words.tutorialContinue), findsNothing);

      await tester.pump(const Duration(seconds: 9));
      expect(find.text(Words.tutorialContinue), findsOneWidget);

      await tester.tap(find.text(Words.tutorialContinue));
      await tester.pump();
      await _settle(tester);

      expect(c.step, TutorialStep.folders);
    });
  });

  group('TutorialSpotlight folder step', () {
    /// A tour already standing on the folder step.
    TutorialController atFolderStep() {
      final c = _touring(addFolder: true);
      while (c.step != TutorialStep.addFolder) {
        c.advance();
      }
      return c;
    }

    testWidgets('asks her to choose, and lets her leave it for later',
        (tester) async {
      _phoneScreen(tester);
      final c = atFolderStep();
      await tester.pumpWidget(_host(c));
      await _settle(tester);

      expect(find.text(Words.tutorialAddFolder), findsOneWidget);
      expect(find.text(Words.tutorialNotNow), findsOneWidget);

      await tester.tap(find.text(Words.tutorialNotNow));
      await tester.pump();
      await _settle(tester);

      expect(c.step, TutorialStep.us);
    });

    testWidgets('only the lit button takes taps on the folder step',
        (tester) async {
      _phoneScreen(tester);
      var button = 0;
      var underneath = 0;
      final c = atFolderStep();
      await tester.pumpWidget(_host(
        c,
        onFolderButtonTap: () => button++,
        onUnderneathTap: () => underneath++,
      ));
      await _settle(tester);

      // The button sits at (20, 400) with a size of 200 by 60.
      await tester.tapAt(const Offset(120, 430));
      await tester.tap(find.text('underneath'), warnIfMissed: false);

      expect(button, 1);
      expect(underneath, 0);
    });

    testWidgets('choosing a folder moves the tour on', (tester) async {
      _phoneScreen(tester);
      final library = _FakeLibrary(null);
      addTearDown(library.dispose);
      final c = atFolderStep();
      await tester.pumpWidget(_host(
        c,
        library: library,
        folderPath: () => library.path,
      ));
      await _settle(tester);

      library.choose('/storage/Music');
      await tester.pump();
      await _settle(tester);

      expect(c.step, TutorialStep.us);
    });

    testWidgets('the library changing without a folder does not',
        (tester) async {
      _phoneScreen(tester);
      final library = _FakeLibrary(null);
      addTearDown(library.dispose);
      final c = atFolderStep();
      await tester.pumpWidget(_host(
        c,
        library: library,
        folderPath: () => library.path,
      ));
      await _settle(tester);

      // Still no folder, whatever else the library announces.
      library.announce();
      await tester.pump();

      expect(c.step, TutorialStep.addFolder);
    });

    testWidgets('picking the folder she already had does not either',
        (tester) async {
      _phoneScreen(tester);
      final library = _FakeLibrary('/storage/Music');
      addTearDown(library.dispose);
      final c = atFolderStep();
      await tester.pumpWidget(_host(
        c,
        library: library,
        folderPath: () => library.path,
      ));
      await _settle(tester);

      library.choose('/storage/Music');
      await tester.pump();
      expect(c.step, TutorialStep.addFolder);

      // A different folder does.
      library.choose('/storage/Other');
      await tester.pump();
      await _settle(tester);
      expect(c.step, TutorialStep.us);
    });
  });

  group('TutorialSpotlight caption while the hole moves', () {
    /// One part near the top and one near the bottom of an 800 high screen,
    /// so the caption belongs below the first and above the second.
    Widget topAndBottom(TutorialController c) {
      return MaterialApp(
        home: Scaffold(
          body: TutorialScope(
            controller: c,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: 20,
                  top: 40,
                  width: 200,
                  height: 60,
                  child: Container(key: c.keyFor(TutorialStep.folders)),
                ),
                Positioned(
                  left: 20,
                  top: 700,
                  width: 200,
                  height: 60,
                  child: Container(key: c.keyFor(TutorialStep.chips)),
                ),
                TutorialSpotlight(controller: c),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('a caption never leaps across the screen on the way',
        (tester) async {
      _phoneScreen(tester);
      final c = _touring();
      await tester.pumpWidget(topAndBottom(c));
      await _settle(tester);

      final folders = find.text(Words.tutorialFolders);
      final chips = find.text(Words.tutorialChips);
      final foldersAt = tester.getTopLeft(folders).dy;
      // Below the top part, which ends at 100.
      expect(foldersAt, greaterThan(100));

      c.advance();
      await tester.pump();

      double? chipsAt;
      for (var i = 0; i < 14; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (folders.evaluate().isNotEmpty) {
          expect(tester.getTopLeft(folders).dy, foldersAt);
        }
        if (chips.evaluate().isNotEmpty) {
          final at = tester.getTopLeft(chips).dy;
          chipsAt ??= at;
          expect(at, chipsAt);
        }
      }

      // It ends above the bottom part, which starts at 700.
      expect(chips, findsOneWidget);
      expect(folders, findsNothing);
      expect(tester.getBottomLeft(chips).dy, lessThan(700));
    });

    testWidgets('only one caption is ever on show', (tester) async {
      _phoneScreen(tester);
      final c = _touring();
      await tester.pumpWidget(topAndBottom(c));
      await _settle(tester);

      c.advance();
      await tester.pump();
      for (var i = 0; i < 14; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        final shown = find.text(Words.tutorialFolders).evaluate().length +
            find.text(Words.tutorialChips).evaluate().length;
        expect(shown, 1);
      }
    });

    testWidgets('the new caption takes no taps until it has arrived',
        (tester) async {
      _phoneScreen(tester);
      final c = _touring();
      await tester.pumpWidget(topAndBottom(c));
      await _settle(tester);

      c.advance();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Neither the leaving card nor the arriving one answers yet.
      await tester.tap(find.text(Labels.welcomeNext), warnIfMissed: false);
      await tester.pump();
      expect(c.step, TutorialStep.chips);

      await _settle(tester);
      await tester.tap(find.text(Labels.welcomeNext));
      await tester.pump();
      expect(c.step, TutorialStep.search);
    });

    testWidgets('waiting for her to press play redraws nothing',
        (tester) async {
      _phoneScreen(tester);
      final c = _touring(song: _song);
      await tester.pumpWidget(_host(c));
      await _settle(tester);

      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
