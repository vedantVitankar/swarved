import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/tutorial/tutorial_controller.dart';

TutorialController _blank() =>
    TutorialController(stage: TutorialStage.blank);

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
}
