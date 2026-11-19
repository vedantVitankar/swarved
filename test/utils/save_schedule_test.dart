import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/utils/save_schedule.dart';

final _t0 = DateTime.utc(2026, 11, 2, 9);
DateTime _at(double seconds) =>
    _t0.add(Duration(milliseconds: (seconds * 1000).round()));

/// Asks at [seconds] and, when told to save, confirms it like the real caller.
bool _ask(
  SaveSchedule schedule,
  double seconds, {
  String signature = 'a',
  bool playing = false,
  double position = 0,
  bool confirm = true,
}) {
  final pos = Duration(milliseconds: (position * 1000).round());
  final yes = schedule.shouldSave(
    signature: signature,
    playing: playing,
    position: pos,
    now: _at(seconds),
  );
  if (yes && confirm) {
    schedule.saved(signature: signature, position: pos, now: _at(seconds));
  }
  return yes;
}

void main() {
  group('SaveSchedule', () {
    test('the first state is written once it has settled, not instantly', () {
      final schedule = SaveSchedule();
      expect(_ask(schedule, 0), isFalse);
      expect(_ask(schedule, 0.2), isFalse);
      expect(_ask(schedule, 0.5), isTrue);
    });

    test('once saved and unchanged while paused, nothing more is written', () {
      final schedule = SaveSchedule();
      _ask(schedule, 0);
      expect(_ask(schedule, 0.5), isTrue);
      for (var s = 1.0; s < 120; s += 1) {
        expect(_ask(schedule, s), isFalse, reason: 'at $s s');
      }
    });

    test('while a song plays, the position is written every ten seconds', () {
      final schedule = SaveSchedule();
      _ask(schedule, 0, playing: true);
      expect(_ask(schedule, 0.5, playing: true), isTrue);
      expect(_ask(schedule, 5, playing: true, position: 5), isFalse);
      expect(_ask(schedule, 10.4, playing: true, position: 10), isFalse);
      expect(_ask(schedule, 10.5, playing: true, position: 10), isTrue);
      expect(_ask(schedule, 15, playing: true, position: 15), isFalse);
      expect(_ask(schedule, 20.5, playing: true, position: 20), isTrue);
    });

    test('a burst of changes is written once, when it has settled', () {
      final schedule = SaveSchedule();
      _ask(schedule, 0);
      _ask(schedule, 0.5); // saved: 'a'
      // She skips through songs quickly.
      expect(_ask(schedule, 10.0, signature: 'b', playing: true), isFalse);
      expect(_ask(schedule, 10.2, signature: 'c', playing: true), isFalse);
      expect(_ask(schedule, 10.4, signature: 'd', playing: true), isFalse);
      expect(_ask(schedule, 10.7, signature: 'd', playing: true), isFalse);
      expect(_ask(schedule, 10.8, signature: 'd', playing: true), isTrue);
      // ... and that was the last one written: the settled state, 'd'.
      expect(_ask(schedule, 11, signature: 'd', playing: true), isFalse);
    });

    test('a change that is undone before it settles writes nothing', () {
      final schedule = SaveSchedule();
      _ask(schedule, 0);
      _ask(schedule, 0.5);
      expect(_ask(schedule, 5, signature: 'b'), isFalse);
      expect(_ask(schedule, 5.2, signature: 'a'), isFalse); // back again
      expect(_ask(schedule, 6, signature: 'a'), isFalse);
    });

    test('pausing writes the place she stopped at, at once', () {
      final schedule = SaveSchedule();
      _ask(schedule, 0, playing: true);
      _ask(schedule, 0.5, playing: true); // saved
      expect(_ask(schedule, 4, playing: true, position: 4), isFalse);
      expect(_ask(schedule, 4.5, playing: false, position: 4.5), isTrue);
      expect(_ask(schedule, 5, playing: false, position: 4.5), isFalse);
    });

    test('moving the slider while paused is saved, a tiny nudge is not', () {
      final schedule = SaveSchedule();
      _ask(schedule, 0);
      _ask(schedule, 0.5);
      expect(_ask(schedule, 3, position: 1), isFalse);
      expect(_ask(schedule, 4, position: 1.9), isFalse);
      expect(_ask(schedule, 5, position: 30), isTrue);
      expect(_ask(schedule, 6, position: 30), isFalse);
    });

    test('saveNext forces one write, then goes back to normal', () {
      final schedule = SaveSchedule();
      _ask(schedule, 0);
      _ask(schedule, 0.5);
      schedule.saveNext();
      expect(_ask(schedule, 2), isTrue);
      expect(_ask(schedule, 3), isFalse);
    });

    test('a write that did not happen is asked for again', () {
      final schedule = SaveSchedule();
      _ask(schedule, 0);
      expect(_ask(schedule, 0.5, confirm: false), isTrue); // the file failed
      expect(_ask(schedule, 1.5, confirm: false), isTrue); // still wanted
      expect(_ask(schedule, 2.5), isTrue);
      expect(_ask(schedule, 3.5), isFalse);
    });
  });
}
