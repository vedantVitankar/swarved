import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/voice_interludes.dart';
import 'package:swarved/utils/voice_planner.dart';

const _a = '0123456789abcdef.mp3';
const _b = 'fedcba9876543210.m4a';
const _c = 'aaaaaaaaaaaaaaaa.ogg';
const _d = 'bbbbbbbbbbbbbbbb.wav';

VoiceInterludes _settings({
  int every = 3,
  int? max,
  String? from,
  String? to,
  List<String> files = const [_a, _b, _c],
}) {
  return VoiceInterludes.parse({
    'everySongs': every,
    if (max != null) 'maxPerDay': max,
    if (from != null) 'quietFrom': from,
    if (to != null) 'quietTo': to,
    'clips': [
      for (final file in files) {'file': file},
    ],
  });
}

List<String> _files(List<VoiceClip> clips) => [for (final c in clips) c.file];

void main() {
  const planner = VoicePlanner();
  final noon = DateTime(2026, 10, 15, 12);

  VoiceClip? choose({
    VoiceInterludes? settings,
    int songs = 3,
    int today = 0,
    DateTime? now,
    Set<String> onPhone = const {_a, _b, _c, _d},
    String? last,
    Set<String> played = const {},
  }) {
    return planner.choose(
      settings: settings ?? _settings(),
      songsSince: songs,
      playedToday: today,
      now: now ?? noon,
      onPhone: onPhone,
      last: last,
      played: played,
    );
  }

  group('when', () {
    test('nothing until enough songs have finished', () {
      expect(choose(songs: 1), isNull);
      expect(choose(songs: 2), isNull);
      expect(choose(songs: 3), isNotNull);
      expect(choose(songs: 9), isNotNull);
    });

    test('never more than the daily limit', () {
      final limited = _settings(max: 2);
      expect(choose(settings: limited, today: 1), isNotNull);
      expect(choose(settings: limited, today: 2), isNull);
      expect(choose(settings: limited, today: 5), isNull);
    });

    test('never in quiet hours', () {
      final quiet = _settings(from: '22:00', to: '07:00');
      expect(choose(settings: quiet, now: DateTime(2026, 10, 15, 23)), isNull);
      expect(choose(settings: quiet, now: DateTime(2026, 10, 15, 6)), isNull);
      expect(choose(settings: quiet, now: noon), isNotNull);
    });
  });

  group('which', () {
    test('the first time, the first in his list', () {
      expect(choose()!.file, _a);
    });

    test('then the next one, in his order', () {
      expect(choose(last: _a, played: {_a})!.file, _b);
      expect(choose(last: _b, played: {_a, _b})!.file, _c);
    });

    test('after the last one nothing plays: it never starts over', () {
      expect(choose(last: _c, played: {_a, _b, _c}), isNull);
    });

    test('a recording added at the end is heard next, not the old ones', () {
      final grown = _settings(files: const [_a, _b, _c, _d]);
      expect(choose(settings: grown, last: _c)!.file, _d);
    });

    test('a recording moved below the last played one is heard again', () {
      // He moved _a to the end: [_b, _c, _a], and _c was played last.
      final moved = _settings(files: const [_b, _c, _a]);
      expect(choose(settings: moved, last: _c)!.file, _a);
    });

    test('one moved above the last played one stays played', () {
      final moved = _settings(files: const [_c, _a, _b]);
      expect(choose(settings: moved, last: _a)!.file, _b);
    });

    test('with no last one, the ones not yet played wait', () {
      expect(choose(played: {_a, _b})!.file, _c);
      expect(choose(played: {_a, _b, _c}), isNull);
    });

    test('a last one that was removed falls back to the played list', () {
      final trimmed = _settings(files: const [_a, _c]);
      expect(choose(settings: trimmed, last: _b, played: {_a, _b})!.file, _c);
    });

    test('a list of one plays once, then waits for something new', () {
      final one = _settings(files: const [_a]);
      expect(choose(settings: one)!.file, _a);
      expect(choose(settings: one, last: _a, played: {_a}), isNull);
    });

    test('the next one in line is never skipped, even if it is not here', () {
      expect(choose(onPhone: const {_b, _c}), isNull);
      expect(choose(last: _a, onPhone: const {_a, _c}), isNull);
      expect(choose(onPhone: const {}), isNull);
    });

    test('no recordings at all is never a voice', () {
      expect(choose(settings: _settings(files: const [])), isNull);
    });
  });

  group('waiting', () {
    final clips = _settings().clips;

    test('after the last played, in order', () {
      expect(_files(VoicePlanner.waiting(clips, last: _a)), [_b, _c]);
      expect(_files(VoicePlanner.waiting(clips, last: _c)), isEmpty);
    });

    test('everything when nothing has played', () {
      expect(_files(VoicePlanner.waiting(clips)), [_a, _b, _c]);
    });
  });
}
