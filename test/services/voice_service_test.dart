import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swarved/models/voice_interludes.dart';
import 'package:swarved/services/voice_service.dart';

const _a = '0123456789abcdef.mp3';
const _b = 'fedcba9876543210.m4a';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VoiceInterludes settings;
  late Set<String> onPhone;
  late DateTime now;
  late VoiceInterludeService service;

  VoiceInterludes make({int every = 2, int? max}) => VoiceInterludes.parse({
        'everySongs': every,
        if (max != null) 'maxPerDay': max,
        'clips': [
          {'file': _a},
          {'file': _b},
        ],
      });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    settings = make();
    onPhone = {_a, _b};
    now = DateTime(2026, 10, 15, 12);
    service = VoiceInterludeService(
      settings: () => settings,
      onPhone: (name) async => onPhone.contains(name) ? File(name) : null,
      clock: () => now,
    );
  });

  test('a voice every second song, counting from the last one', () async {
    expect(await service.afterSong(), isNull); // song 1
    expect(await service.afterSong(), isNotNull); // song 2
    expect(await service.afterSong(), isNull); // song 3
    expect(await service.afterSong(), isNotNull); // song 4
  });

  test('the recordings play in his order, and go round again', () async {
    final names = <String>[];
    for (var i = 0; i < 10; i++) {
      final file = await service.afterSong();
      if (file != null) names.add(file.path);
    }
    expect(names, [_a, _b, _a, _b, _a]);
  });

  test('reordering the list changes what comes next', () async {
    await service.afterSong();
    expect((await service.afterSong())!.path, _a);

    settings = VoiceInterludes.parse({
      'everySongs': 2,
      'clips': [
        {'file': _b},
        {'file': _a},
      ],
    });
    await service.afterSong();
    expect((await service.afterSong())!.path, _b, reason: 'after a: b is next');
    await service.afterSong();
    expect((await service.afterSong())!.path, _a, reason: 'in the new order');
  });

  test('no recordings, no voice', () async {
    settings = VoiceInterludes.none;
    for (var i = 0; i < 5; i++) {
      expect(await service.afterSong(), isNull);
    }
  });

  test('a recording that is not on the phone yet is never waited for',
      () async {
    onPhone = {};
    for (var i = 0; i < 6; i++) {
      expect(await service.afterSong(), isNull);
    }
    onPhone = {_a};
    expect((await service.afterSong())!.path, _a, reason: 'it is due at once');
  });

  test('the daily limit holds, and a new day starts again', () async {
    settings = make(every: 1, max: 2);
    expect(await service.afterSong(), isNotNull);
    expect(await service.afterSong(), isNotNull);
    expect(await service.afterSong(), isNull);
    expect(await service.afterSong(), isNull);

    now = DateTime(2026, 10, 16, 9);
    expect(await service.afterSong(), isNotNull);
  });

  test('the limit and the round survive the app being closed', () async {
    settings = make(every: 1, max: 1);
    final first = await service.afterSong();
    expect(first, isNotNull);

    final again = VoiceInterludeService(
      settings: () => settings,
      onPhone: (name) async => File(name),
      clock: () => now,
    );
    expect(await again.afterSong(), isNull, reason: 'already played today');

    now = DateTime(2026, 10, 16, 9);
    final next = await again.afterSong();
    expect(first!.path, _a);
    expect(next!.path, _b, reason: 'the next one in his order is due');
  });

  test('quiet hours hold a voice back until they are over', () async {
    settings = VoiceInterludes.parse({
      'everySongs': 1,
      'quietFrom': '22:00',
      'quietTo': '07:00',
      'clips': [
        {'file': _a},
      ],
    });
    now = DateTime(2026, 10, 15, 23);
    expect(await service.afterSong(), isNull);
    now = DateTime(2026, 10, 16, 8);
    expect(await service.afterSong(), isNotNull);
  });

  test('a lookup that fails gives no voice and does not throw', () async {
    final broken = VoiceInterludeService(
      settings: () => settings,
      onPhone: (name) async => throw const FileSystemException('gone'),
      clock: () => now,
    );
    for (var i = 0; i < 3; i++) {
      expect(await broken.afterSong(), isNull);
    }
  });
}
