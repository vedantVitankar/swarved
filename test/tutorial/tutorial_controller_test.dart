import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/tutorial/tutorial_controller.dart';
import 'package:swarved/tutorial/tutorial_step.dart';

TutorialController _blank() => TutorialController(stage: TutorialStage.blank);

void _walkToTheEnd(TutorialController c) {
  c
    ..start()
    ..glide()
    ..reveal()
    ..finish();
}

void main() {
  group('TutorialController with no intro', () {
    test('everything shows and nothing is covered', () {
      final c = TutorialController();

      expect(c.stage, TutorialStage.off);
      expect(c.active, isFalse);
      expect(c.blocksVisible, isTrue);
      expect(c.greetingVisible, isTrue);
      expect(c.noteVisible, isTrue);
    });

    test('starting does nothing', () {
      final c = TutorialController();
      var calls = 0;
      c.addListener(() => calls++);

      c.start();

      expect(c.stage, TutorialStage.off);
      expect(calls, 0);
    });
  });

  group('TutorialController stages', () {
    test('starts blank, hidden and covered', () {
      final c = _blank();

      expect(c.stage, TutorialStage.blank);
      expect(c.active, isTrue);
      expect(c.blocksVisible, isFalse);
      expect(c.greetingVisible, isFalse);
      expect(c.noteVisible, isFalse);
    });

    test('goes through the stages in order', () {
      final c = _blank();
      final seen = <TutorialStage>[];
      c.addListener(() => seen.add(c.stage));

      _walkToTheEnd(c);

      expect(seen, [
        TutorialStage.typing,
        TutorialStage.gliding,
        TutorialStage.revealing,
        TutorialStage.finished,
      ]);
    });

    test('the greeting and blocks show from the reveal on', () {
      final c = _blank();

      c.start();
      expect(c.blocksVisible, isFalse);
      c.glide();
      expect(c.blocksVisible, isFalse);
      c.reveal();
      expect(c.blocksVisible, isTrue);
      expect(c.greetingVisible, isTrue);
      expect(c.active, isTrue);
      c.finish();
      expect(c.blocksVisible, isTrue);
      expect(c.active, isFalse);
    });

    test('a stage cannot be skipped or repeated', () {
      final c = _blank();
      var calls = 0;
      c.addListener(() => calls++);

      c.glide();
      c.reveal();
      c.finish();
      expect(c.stage, TutorialStage.blank);

      c.start();
      c.start();
      c.reveal();
      expect(c.stage, TutorialStage.typing);
      expect(calls, 1);
    });
  });

  group('TutorialController home note', () {
    test('stays out until the intro is over', () {
      final c = _blank();

      c.start();
      c.glide();
      c.reveal();

      expect(c.noteVisible, isFalse);
    });

    test('appears when the intro finishes with Home on screen', () {
      final c = _blank();

      _walkToTheEnd(c);

      expect(c.noteVisible, isTrue);
    });

    test('waits for Home if the intro finished while she was elsewhere', () {
      final c = _blank();
      c.setHomeVisible(false);

      _walkToTheEnd(c);
      expect(c.noteVisible, isFalse);

      var calls = 0;
      c.addListener(() => calls++);
      c.setHomeVisible(true);

      expect(c.noteVisible, isTrue);
      expect(calls, 1);
    });

    test('once shown it stays, wherever she goes', () {
      final c = _blank();
      _walkToTheEnd(c);

      c.setHomeVisible(false);
      c.setHomeVisible(true);

      expect(c.noteVisible, isTrue);
    });

    test('moving between tabs before the intro ends reveals nothing', () {
      final c = _blank();
      var calls = 0;
      c.addListener(() => calls++);

      c.setHomeVisible(false);
      c.setHomeVisible(true);

      expect(c.noteVisible, isFalse);
      expect(calls, 0);
    });
  });

  group('TutorialController tour', () {
    TutorialController touring(
        {bool withSong = false, bool addFolder = false}) {
      final c = TutorialController(stage: TutorialStage.blank, tour: true)
        ..start(withSong: withSong, addFolder: addFolder)
        ..glide()
        ..reveal()
        ..finish();
      return c;
    }

    test('without the tour the opening is the whole tutorial', () {
      final c = _blank();

      _walkToTheEnd(c);

      expect(c.stage, TutorialStage.finished);
      expect(c.touring, isFalse);
    });

    test('with the tour the opening leads into it', () {
      final c = touring();

      expect(c.stage, TutorialStage.touring);
      expect(c.touring, isTrue);
      expect(c.active, isTrue);
      expect(c.opening, isFalse);
      expect(c.noteVisible, isFalse);
    });

    test('with a song on the tour includes the mini player', () {
      final c = touring(withSong: true);

      // Pressing play is not part of the tour: that was in the welcome.
      expect(c.step, TutorialStep.folders);
      expect(c.steps, tutorialSteps(withSong: true));
      expect(c.steps, contains(TutorialStep.player));
    });

    test('without a song the tour leaves out the mini player', () {
      final c = touring();

      expect(c.step, TutorialStep.folders);
      expect(c.steps, isNot(contains(TutorialStep.player)));
    });

    test('advance walks the steps in order, then finishes', () {
      final c = touring(withSong: true, addFolder: true);
      final seen = <TutorialStep?>[c.step];

      while (c.touring) {
        c.advance();
        seen.add(c.step);
      }

      expect(seen, [...TutorialStep.values, null]);
      expect(c.stage, TutorialStage.finished);
      expect(c.noteVisible, isTrue);
    });

    test('skip leaves the tour from any step and brings the note', () {
      final c = touring(withSong: true);
      c.advance();
      c.advance();

      c.skip();

      expect(c.stage, TutorialStage.finished);
      expect(c.step, isNull);
      expect(c.active, isFalse);
      expect(c.noteVisible, isTrue);
    });

    test('advance and skip do nothing outside the tour', () {
      final c = _blank();
      var calls = 0;
      c.addListener(() => calls++);

      c.advance();
      c.skip();

      expect(c.stage, TutorialStage.blank);
      expect(calls, 0);
    });

    test('the note waits for Home if the tour ends elsewhere', () {
      final c = touring();
      c.setHomeVisible(false);

      c.skip();
      expect(c.noteVisible, isFalse);

      c.setHomeVisible(true);
      expect(c.noteVisible, isTrue);
    });

    test('each step has one key, and only three tabs have one', () {
      final c = _blank();

      expect(c.keyFor(TutorialStep.chips), same(c.keyFor(TutorialStep.chips)));
      expect(c.keyFor(TutorialStep.chips),
          isNot(same(c.keyFor(TutorialStep.folders))));
      expect(c.navKey(0), isNull);
      expect(c.navKey(1), same(c.keyFor(TutorialStep.search)));
      expect(c.navKey(2), same(c.keyFor(TutorialStep.library)));
      expect(c.navKey(3), same(c.keyFor(TutorialStep.us)));
      expect(c.navKey(4), isNull);
    });
  });

  group('TutorialController what shows when', () {
    TutorialController touring({bool withSong = false}) {
      return TutorialController(stage: TutorialStage.blank, tour: true)
        ..start(withSong: withSong)
        ..glide()
        ..reveal()
        ..finish();
    }

    test('before the opening nothing of Home may show', () {
      final c = _blank();

      expect(c.restVisible, isFalse);
      expect(c.noteVisible, isFalse);
    });

    test('the rest of Home comes with the reveal, whatever is playing', () {
      for (final withSong in [false, true]) {
        final c = TutorialController(stage: TutorialStage.blank, tour: true)
          ..start(withSong: withSong)
          ..glide()
          ..reveal();

        expect(c.restVisible, isTrue, reason: 'withSong: $withSong');
        expect(c.noteVisible, isFalse, reason: 'withSong: $withSong');
      }
    });

    test('the rest stays on through the tour', () {
      final c = touring(withSong: true);

      expect(c.touring, isTrue);
      expect(c.restVisible, isTrue);
      c.advance();
      expect(c.restVisible, isTrue);
    });

    test('the song of the day and the note wait for the end of the tour', () {
      final c = touring(withSong: true);

      expect(c.noteVisible, isFalse);
      c.advance();
      expect(c.noteVisible, isFalse);

      c.skip();
      expect(c.noteVisible, isTrue);
    });

    test('with no tutorial at all everything shows', () {
      final c = TutorialController();

      expect(c.restVisible, isTrue);
      expect(c.noteVisible, isTrue);
    });
  });

  group('TutorialController folder step', () {
    TutorialController touring({bool addFolder = true}) {
      return TutorialController(stage: TutorialStage.blank, tour: true)
        ..start(addFolder: addFolder)
        ..glide()
        ..reveal()
        ..finish();
    }

    void walkTo(TutorialController c, TutorialStep step) {
      while (c.step != step) {
        c.advance();
      }
    }

    test('is part of the tour only when asked for', () {
      expect(touring().steps, contains(TutorialStep.addFolder));
      expect(touring(addFolder: false).steps,
          isNot(contains(TutorialStep.addFolder)));
    });

    test('the shell is on Home except while the folder is asked for', () {
      final c = touring();

      expect(c.wantedTab, TutorialController.homeTab);
      walkTo(c, TutorialStep.library);
      expect(c.wantedTab, TutorialController.homeTab);
      c.advance();
      expect(c.step, TutorialStep.addFolder);
      expect(c.wantedTab, TutorialController.libraryTab);
      c.advance();
      expect(c.step, TutorialStep.us);
      expect(c.wantedTab, TutorialController.homeTab);
    });

    test('skipping from the folder step goes back to Home', () {
      final c = touring();
      walkTo(c, TutorialStep.addFolder);

      c.skip();

      expect(c.wantedTab, TutorialController.homeTab);
    });

    test('with no tutorial at all the shell stays on Home', () {
      expect(TutorialController().wantedTab, TutorialController.homeTab);
    });
  });
}
