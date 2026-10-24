import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swarved/models/voice_interludes.dart';
import 'package:swarved/services/voice_service.dart';

const _a = '0123456789abcdef.mp3';
const _b = 'fedcba9876543210.m4a';
const _c = 'aaaaaaaaaaaaaaaa.ogg';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VoiceInterludes settings;
  late Set<String> onPhone;
  late DateTime now;
  late List<String> downloads;
  late List<String> reports;
  late VoiceInterludeService service;

  VoiceInterludes make({
    int every = 2,
    int? max,
    List<String> files = const [_a, _b],
    String? reset,
  }) {
    return VoiceInterludes.parse({
      'everySongs': every,
      if (max != null) 'maxPerDay': max,
      if (reset != null) 'resetToken': reset,
      'clips': [
        for (final file in files) {'file': file},
      ],
    });
  }

  VoiceInterludeService build() => VoiceInterludeService(
        settings: () => settings,
        onPhone: (name) async => onPhone.contains(name) ? File(name) : null,
        download: downloads.add,
        report: (last, played) => reports.add('$last:${played.join(',')}'),
        clock: () => now,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    settings = make();
    onPhone = {_a, _b, _c};
    now = DateTime(2026, 10, 15, 12);
    downloads = [];
    reports = [];
    service = build();
  });

  Future<List<String>> run(int songs, [VoiceInterludeService? who]) async {
    final names = <String>[];
    for (var i = 0; i < songs; i++) {
      final file = await (who ?? service).afterSong();
      if (file != null) names.add(file.path);
    }
    return names;
  }

  test('a voice every second song, counting from the last one', () async {
    expect(await service.afterSong(), isNull); // song 1
    expect(await service.afterSong(), isNotNull); // song 2
    expect(await service.afterSong(), isNull); // song 3
    expect(await service.afterSong(), isNotNull); // song 4
  });

  test('they play in his order, then stop: it never starts over', () async {
    settings = make(every: 1, files: const [_a, _b, _c]);
    expect(await run(8), [_a, _b, _c]);
  });

  test('a recording added later is heard next, not the old ones again',
      () async {
    settings = make(every: 1, files: const [_a, _b]);
    expect(await run(5), [_a, _b]);

    settings = make(every: 1, files: const [_a, _b, _c]);
    expect(await run(3), [_c]);
  });

  test('one moved below the last played one plays again', () async {
    settings = make(every: 1, files: const [_a, _b]);
    expect(await run(3), [_a, _b]);

    settings = make(every: 1, files: const [_b, _a]); // _a moved to the end
    expect(await run(3), [_a]);
  });

  test('each play is reported with everything played so far', () async {
    settings = make(every: 1, files: const [_a, _b]);
    await run(2);
    expect(reports, ['$_a:$_a', '$_b:$_a,$_b']);
  });

  test('no recordings, no voice', () async {
    settings = VoiceInterludes.none;
    expect(await run(5), isEmpty);
    expect(reports, isEmpty);
  });

  test('the next one in line that is not here is fetched, never skipped',
      () async {
    onPhone = {_b};
    settings = make(every: 1);
    expect(await run(3), isEmpty, reason: '_a is next, and not here yet');
    expect(downloads, [_a, _a, _a]);

    onPhone = {_a, _b};
    expect(await run(1), [_a], reason: 'in order, as soon as it arrived');
  });

  test('the daily limit holds, and a new day starts again', () async {
    settings = make(every: 1, max: 2, files: const [_a, _b, _c]);
    expect(await run(4), [_a, _b]);

    now = DateTime(2026, 10, 16, 9);
    expect(await run(1), [_c]);
  });

  test('where it got to survives the app being closed', () async {
    settings = make(every: 1, max: 1, files: const [_a, _b]);
    expect(await run(1), [_a]);

    final again = build();
    expect(await run(1, again), isEmpty, reason: 'already played today');

    now = DateTime(2026, 10, 16, 9);
    expect(await run(1, again), [_b], reason: 'the next one in his order');
  });

  test('"reset played status" starts over from the top, once', () async {
    settings = make(every: 1, files: const [_a, _b]);
    expect(await run(3), [_a, _b]);

    settings = make(every: 1, files: const [_a, _b], reset: '100');
    reports.clear();
    expect(await run(3), [_a, _b]);
    expect(reports.first, 'null:', reason: 'the server is told');

    expect(await run(3), isEmpty,
        reason: 'the same token does not reset again');

    settings = make(every: 1, files: const [_a, _b], reset: '200');
    expect(await run(3), [_a, _b]);
  });

  test('it tells the server where it got to without a voice playing', () async {
    settings = make(every: 1, files: const [_a, _b]);
    await run(3); // _a, then _b, then nothing is left
    reports.clear();

    await service.syncProgress();
    expect(reports, ['$_b:$_a,$_b'], reason: 'everything has played');
  });

  test('a phone that only kept which one played last reports that', () async {
    SharedPreferences.setMockInitialValues({'voice_last_v1': _b});
    settings = make(every: 1, files: const [_a, _b]);

    await service.syncProgress();
    expect(reports, ['$_b:'], reason: 'the admin works out the rest');
  });

  test('syncing says nothing when there are no recordings', () async {
    settings = make(files: const []);
    await service.syncProgress();
    expect(reports, isEmpty);
  });

  test('a reset is applied and reported as soon as the content has it',
      () async {
    settings = make(every: 1, files: const [_a, _b]);
    expect(await run(3), [_a, _b]);
    reports.clear();

    settings = make(every: 1, files: const [_a, _b], reset: '100');
    await service.syncProgress();
    expect(reports, ['null:'], reason: 'one report, not two');

    expect(await run(3), [_a, _b], reason: 'heard again from the top');
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
    expect(await run(3, broken), isEmpty);
  });
}
