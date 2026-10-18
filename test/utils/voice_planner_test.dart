import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/voice_interludes.dart';
import 'package:swarved/utils/voice_planner.dart';

const _a = '0123456789abcdef.mp3';
const _b = 'fedcba9876543210.m4a';
const _c = 'aaaaaaaaaaaaaaaa.ogg';

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

void main() {
  const planner = VoicePlanner();
  final noon = DateTime(2026, 10, 15, 12);

  VoiceClip? choose({
    VoiceInterludes? settings,
    int songs = 3,
    int today = 0,
    DateTime? now,
    Set<String> onPhone = const {_a, _b, _c},
    String? last,
  }) {
    return planner.choose(
      settings: settings ?? _settings(),
      songsSince: songs,
      playedToday: today,
      now: now ?? noon,
      onPhone: onPhone,
      lastPlayed: last,
    );
  }

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

  test('the first time, the first recording in his list', () {
    expect(choose()!.file, _a);
  });

  test('then the next one, in his order, and round again from the top', () {
    expect(choose(last: _a)!.file, _b);
    expect(choose(last: _b)!.file, _c);
    expect(choose(last: _c)!.file, _a);
  });

  test('a list of one plays that one every time', () {
    final one = _settings(files: const [_a]);
    expect(choose(settings: one)!.file, _a);
    expect(choose(settings: one, last: _a)!.file, _a);
  });

  test('moving the recordings around changes what comes next', () {
    final reordered = _settings(files: const [_c, _a, _b]);
    expect(choose(settings: reordered, last: _a)!.file, _b);
    expect(choose(settings: reordered, last: _b)!.file, _c);
  });

  test('a last one no longer in the list starts from the top', () {
    final trimmed = _settings(files: const [_b, _c]);
    expect(choose(settings: trimmed, last: _a)!.file, _b);
  });

  test('a recording not on the phone yet is skipped over, not waited for', () {
    expect(choose(onPhone: const {_a, _c}, last: _a)!.file, _c);
    expect(choose(onPhone: const {_b, _c})!.file, _b);
    expect(choose(onPhone: const {_a}, last: _a)!.file, _a);
    expect(choose(onPhone: const {}), isNull);
  });

  test('no recordings at all is never a voice', () {
    expect(choose(settings: _settings(files: const [])), isNull);
  });
}
