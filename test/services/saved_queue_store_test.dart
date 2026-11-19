import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/saved_queue.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/services/saved_queue_store.dart';

SavedQueue _saved(String id, {int seconds = 30}) => SavedQueue(
      tracks: [
        Track.youtube(
          videoId: id,
          title: 'Song $id',
          artist: 'Artist',
          duration: const Duration(seconds: 200),
        ),
      ],
      index: 0,
      position: Duration(seconds: seconds),
      savedAt: DateTime.utc(2026, 11, 2),
    );

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('queue_store_test'));
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  FileSavedQueueStore store({String? profile, String? defaultProfile}) =>
      FileSavedQueueStore(
        directory: () async => dir,
        profile: profile,
        defaultProfile: defaultProfile,
      );

  group('FileSavedQueueStore', () {
    test('nothing saved yet reads as nothing', () async {
      expect(await store().read(), isNull);
    });

    test('what is written is read back', () async {
      final s = store();
      await s.write(_saved('aaaaaaaaaaa', seconds: 77));
      final back = (await s.read())!;
      expect(back.current.videoId, 'aaaaaaaaaaa');
      expect(back.position, const Duration(seconds: 77));
    });

    test('the newest write wins, and no temporary file is left behind',
        () async {
      final s = store();
      await s.write(_saved('aaaaaaaaaaa'));
      await s.write(_saved('bbbbbbbbbbb'));
      expect((await s.read())!.current.videoId, 'bbbbbbbbbbb');
      expect(
          dir
              .listSync()
              .map((e) => e.path.split(Platform.pathSeparator).last)
              .toList(),
          ['queue_v1.json']);
    });

    test('many writes started at once all finish, in order, without clashing',
        () async {
      final s = store();
      await Future.wait([
        for (var i = 0; i < 25; i++)
          s.write(_saved('abcdefghij$i'.substring(0, 11), seconds: i)),
      ]);
      expect((await s.read())!.position, const Duration(seconds: 24));
      expect(dir.listSync().length, 1);
    });

    test(
        'a damaged file reads as nothing instead of crashing, and is replaced by the next save',
        () async {
      File('${dir.path}${Platform.pathSeparator}queue_v1.json')
          .writeAsStringSync('{"tracks": [');
      final s = store();
      expect(await s.read(), isNull);
      await s.write(_saved('aaaaaaaaaaa'));
      expect(await s.read(), isNotNull);
    });

    test('a file that is valid JSON but not a saved queue reads as nothing',
        () async {
      File('${dir.path}${Platform.pathSeparator}queue_v1.json')
          .writeAsStringSync(jsonEncode({'hello': 1}));
      expect(await store().read(), isNull);
    });

    test('clear removes it, and clearing nothing is fine', () async {
      final s = store();
      await s.clear();
      await s.write(_saved('aaaaaaaaaaa'));
      await s.clear();
      expect(await s.read(), isNull);
    });

    test('a folder that does not exist yet is created', () async {
      final deeper = Directory(
          '${dir.path}${Platform.pathSeparator}a${Platform.pathSeparator}b');
      final s = FileSavedQueueStore(directory: () async => deeper);
      await s.write(_saved('aaaaaaaaaaa'));
      expect(await s.read(), isNotNull);
    });

    test(
        'the test copy of the app keeps its own file, hers keeps the plain name',
        () async {
      final hers = store(profile: 'swarnima', defaultProfile: 'swarnima');
      final theirs = store(profile: 'test', defaultProfile: 'swarnima');
      expect(hers.fileName, 'queue_v1.json');
      expect(theirs.fileName, 'queue_test_v1.json');
      await hers.write(_saved('aaaaaaaaaaa'));
      expect(await theirs.read(), isNull);
      await theirs.write(_saved('bbbbbbbbbbb'));
      expect((await hers.read())!.current.videoId, 'aaaaaaaaaaa');
    });
  });
}
