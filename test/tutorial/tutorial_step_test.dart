import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/content/words.dart';
import 'package:swarved/tutorial/tutorial_step.dart';

void main() {
  group('tutorialSteps', () {
    test('with a song every step is there, in order, bar the folder', () {
      expect(tutorialSteps(withSong: true), [
        TutorialStep.folders,
        TutorialStep.chips,
        TutorialStep.player,
        TutorialStep.search,
        TutorialStep.library,
        TutorialStep.us,
      ]);
    });

    test('the folder step comes after Library and before Us', () {
      final steps = tutorialSteps(withSong: true, addFolder: true);

      expect(steps, TutorialStep.values);
      expect(steps.indexOf(TutorialStep.addFolder),
          steps.indexOf(TutorialStep.library) + 1);
      expect(steps.last, TutorialStep.us);
    });

    test('without a song or a folder step the tour is the five parts', () {
      expect(tutorialSteps(withSong: false, addFolder: false).length, 5);
      expect(tutorialSteps(withSong: false, addFolder: true).length, 6);
    });

    test('without a song the mini player is left out', () {
      expect(tutorialSteps(withSong: false), [
        TutorialStep.folders,
        TutorialStep.chips,
        TutorialStep.search,
        TutorialStep.library,
        TutorialStep.us,
      ]);
    });

    test('she acts herself on the folder step only', () {
      final interactive = [
        for (final step in TutorialStep.values)
          if (step.isInteractive) step,
      ];

      expect(interactive, [TutorialStep.addFolder]);
    });

    test('only the mini player needs a song', () {
      final needing = [
        for (final step in TutorialStep.values)
          if (step.needsSong) step,
      ];

      expect(needing, [TutorialStep.player]);
    });

    test('there is no step that asks her to press play', () {
      // That moved to the welcome.
      final names = TutorialStep.values.map((step) => step.name);

      expect(names, isNot(contains('play')));
    });
  });

  group('tutorialCaption', () {
    test('every step has a default caption', () {
      for (final step in TutorialStep.values) {
        expect(tutorialCaption(step), isNotEmpty, reason: '$step');
      }
    });

    test('his own caption wins', () {
      expect(
        tutorialCaption(TutorialStep.player, own: {'player': 'Go on, baby.'}),
        'Go on, baby.',
      );
    });

    test('a blank caption of his falls back to the default', () {
      expect(
        tutorialCaption(TutorialStep.chips, own: {'chips': '   '}),
        Words.tutorialChips,
      );
    });

    test('a caption for another step does not leak in', () {
      expect(
        tutorialCaption(TutorialStep.search, own: {'library': 'Mine.'}),
        Words.tutorialSearch,
      );
    });

    test('with no folders the folders step says where they will be', () {
      expect(
        tutorialCaption(TutorialStep.folders, noFolders: true),
        Words.tutorialFoldersEmpty,
      );
      expect(
        tutorialCaption(TutorialStep.folders),
        Words.tutorialFolders,
      );
    });

    test('the folder step has its own default caption', () {
      expect(tutorialCaption(TutorialStep.addFolder), Words.tutorialAddFolder);
      expect(
        tutorialCaption(TutorialStep.addFolder, own: {'addFolder': 'Here.'}),
        'Here.',
      );
    });

    test('his caption for folders is used even with no folders', () {
      expect(
        tutorialCaption(
          TutorialStep.folders,
          own: {'folders': 'Mine.'},
          noFolders: true,
        ),
        'Mine.',
      );
    });
  });
}
