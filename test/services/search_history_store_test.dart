import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/search_history_entry.dart';
import 'package:swarved/services/search_history_store.dart';

SearchHistoryEntry _e(String id) => SearchHistoryEntry(
      id: 'yt:$id',
      isLocal: false,
      title: 'Song $id',
      artist: 'A',
      durationSeconds: 90,
      videoId: id,
    );

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('history_store_test'));
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  FileSearchHistoryStore store({String? profile, String? defaultProfile}) =>
      FileSearchHistoryStore(
        directory: () async => dir,
        profile: profile,
        defaultProfile: defaultProfile,
      );

  List<String> files() => dir
      .listSync()
      .map((e) => e.path.split(Platform.pathSeparator).last)
      .toList();

  group('FileSearchHistoryStore', () {
    test('nothing saved yet reads as an empty list', () async {
      expect(await store().read(), isEmpty);
    });

    test('what is written is read back, in order', () async {
      final s = store();
      await s.write([_e('bbbbbbbbbbb'), _e('aaaaaaaaaaa')]);
      final back = await s.read();
      expect([for (final e in back) e.id], ['yt:bbbbbbbbbbb', 'yt:aaaaaaaaaaa']);
      expect(back.first.durationSeconds, 90);
    });

    test('the newest write wins and no temporary file is left behind',
        () async {
      final s = store();
      await s.write([_e('aaaaaaaaaaa')]);
      await s.write([_e('bbbbbbbbbbb')]);
      expect((await s.read()).single.id, 'yt:bbbbbbbbbbb');
      expect(files(), ['search_history_v1.json']);
    });

    test('writes made one after another are all kept in order', () async {
      final s = store();
      final writes = [
        for (var i = 0; i < 5; i++) s.write([_e('id$i')]),
      ];
      await Future.wait(writes);
      expect((await s.read()).single.id, 'yt:id4');
    });

    test('a damaged file reads as empty and the next save replaces it',
        () async {
      File('${dir.path}/search_history_v1.json').writeAsStringSync('{ not json');
      final s = store();
      expect(await s.read(), isEmpty);
      await s.write([_e('aaaaaaaaaaa')]);
      expect((await s.read()).single.id, 'yt:aaaaaaaaaaa');
    });

    test('a file of the wrong shape reads as empty', () async {
      File('${dir.path}/search_history_v1.json')
          .writeAsStringSync(jsonEncode([1, 2, 3]));
      expect(await store().read(), isEmpty);
    });

    test('one bad entry does not spoil the others', () async {
      File('${dir.path}/search_history_v1.json').writeAsStringSync(jsonEncode({
        'version': 1,
        'entries': [
          _e('aaaaaaaaaaa').toJson(),
          {'id': 5},
          _e('bbbbbbbbbbb').toJson(),
        ],
      }));
      final back = await store().read();
      expect([for (final e in back) e.id], ['yt:aaaaaaaaaaa', 'yt:bbbbbbbbbbb']);
    });

    test('hers keeps the plain file name and the test copy has its own',
        () async {
      await store(profile: 'swarnima', defaultProfile: 'swarnima')
          .write([_e('aaaaaaaaaaa')]);
      await store(profile: 'test', defaultProfile: 'swarnima')
          .write([_e('bbbbbbbbbbb')]);
      expect(files()..sort(),
          ['search_history_test_v1.json', 'search_history_v1.json']);

      final hers = await store(profile: 'swarnima', defaultProfile: 'swarnima').read();
      final test = await store(profile: 'test', defaultProfile: 'swarnima').read();
      expect(hers.single.id, 'yt:aaaaaaaaaaa');
      expect(test.single.id, 'yt:bbbbbbbbbbb');
    });
  });
}
