import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/content_pack.dart';
import 'package:swarved/models/voice_interludes.dart';

const _a = '0123456789abcdef.mp3';
const _b = 'fedcba9876543210.m4a';

void main() {
  group('VoiceInterludes.parse', () {
    test('nothing, or something that is not an object, is no voices', () {
      expect(VoiceInterludes.parse(null).isOn, isFalse);
      expect(VoiceInterludes.parse('x').isOn, isFalse);
      expect(VoiceInterludes.parse([1]).isOn, isFalse);
      expect(VoiceInterludes.parse({}).isOn, isFalse);
    });

    test('reads the settings and the recordings', () {
      final voices = VoiceInterludes.parse({
        'everySongs': 3,
        'maxPerDay': 2,
        'quietFrom': '22:00',
        'quietTo': '07:30',
        'clips': [
          {'file': _a, 'caption': ' Good morning '},
          {'file': _b},
        ],
      });
      expect(voices.isOn, isTrue);
      expect(voices.everySongs, 3);
      expect(voices.maxPerDay, 2);
      expect(voices.quietFrom, 22 * 60);
      expect(voices.quietTo, 7 * 60 + 30);
      expect([for (final c in voices.clips) c.file], [_a, _b]);
      expect(voices.clips.first.caption, 'Good morning');
    });

    test('a missing "every" falls back, a missing limit means no limit', () {
      final voices = VoiceInterludes.parse({
        'clips': [
          {'file': _a},
        ],
      });
      expect(voices.everySongs, VoiceInterludes.defaultEverySongs);
      expect(voices.maxPerDay, isNull);
    });

    test('bad numbers and times are ignored', () {
      final voices = VoiceInterludes.parse({
        'everySongs': 0,
        'maxPerDay': -1,
        'quietFrom': '25:00',
        'quietTo': 'soon',
        'clips': [
          {'file': _a},
        ],
      });
      expect(voices.everySongs, VoiceInterludes.defaultEverySongs);
      expect(voices.maxPerDay, isNull);
      expect(voices.quietFrom, isNull);
      expect(voices.quietTo, isNull);
    });

    test('numbers written as text or with a fraction of zero are accepted', () {
      final voices = VoiceInterludes.parse({
        'everySongs': '4',
        'maxPerDay': 2.0,
      });
      expect(voices.everySongs, 4);
      expect(voices.maxPerDay, 2);
    });

    test('bad and repeated recordings are skipped', () {
      final voices = VoiceInterludes.parse({
        'clips': [
          'nonsense',
          {'file': 5},
          {'file': '../etc/passwd'},
          {'file': 'photo0123456789a.jpg'},
          {'file': _a},
          {'file': _a},
        ],
      });
      expect([for (final c in voices.clips) c.file], [_a]);
    });
  });

  group('the reset token', () {
    test('is read, trimmed', () {
      expect(VoiceInterludes.parse({'resetToken': ' 1760 '}).restart, '1760');
    });

    test('is none when missing, empty or not text', () {
      expect(VoiceInterludes.parse({}).restart, isNull);
      expect(VoiceInterludes.parse({'resetToken': ' '}).restart, isNull);
      expect(VoiceInterludes.parse({'resetToken': 5}).restart, isNull);
    });
  });

  group('quiet hours', () {
    VoiceInterludes quiet(String from, String to) => VoiceInterludes.parse({
          'quietFrom': from,
          'quietTo': to,
        });

    test('within a day', () {
      final v = quiet('13:00', '15:00');
      expect(v.isQuietAt(DateTime(2026, 10, 15, 12, 59)), isFalse);
      expect(v.isQuietAt(DateTime(2026, 10, 15, 13)), isTrue);
      expect(v.isQuietAt(DateTime(2026, 10, 15, 14, 59)), isTrue);
      expect(v.isQuietAt(DateTime(2026, 10, 15, 15)), isFalse);
    });

    test('running past midnight', () {
      final v = quiet('22:00', '07:00');
      expect(v.isQuietAt(DateTime(2026, 10, 15, 21, 59)), isFalse);
      expect(v.isQuietAt(DateTime(2026, 10, 15, 22)), isTrue);
      expect(v.isQuietAt(DateTime(2026, 10, 15, 3)), isTrue);
      expect(v.isQuietAt(DateTime(2026, 10, 15, 7)), isFalse);
    });

    test('only one end, or the same twice, is never quiet', () {
      expect(
        VoiceInterludes.parse({'quietFrom': '22:00'})
            .isQuietAt(DateTime(2026, 10, 15, 23)),
        isFalse,
      );
      expect(quiet('10:00', '10:00').isQuietAt(DateTime(2026, 10, 15, 10)),
          isFalse);
    });
  });

  test('the content pack carries the voices', () {
    final pack = ContentPack.parse(
      '{"voices": {"everySongs": 2, "clips": [{"file": "$_a"}]}}',
    );
    expect(pack.voices.everySongs, 2);
    expect(pack.voices.clips.single.file, _a);
    expect(pack.mediaFiles, {_a}, reason: 'so the file is downloaded');
    expect(ContentPack.parse('{}').voices.isOn, isFalse);
  });
}
