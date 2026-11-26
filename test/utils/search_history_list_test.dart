import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/search_history_entry.dart';
import 'package:swarved/utils/search_history_list.dart';

SearchHistoryEntry _e(String id) => SearchHistoryEntry(
      id: 'yt:$id',
      isLocal: false,
      title: 'Song $id',
      artist: 'A',
      videoId: id,
    );

List<String> _ids(List<SearchHistoryEntry> list) =>
    [for (final e in list) e.id];

void main() {
  group('withRecorded', () {
    test('the newest song goes to the top', () {
      final list = withRecorded([_e('b'), _e('a')], _e('c'));
      expect(_ids(list), ['yt:c', 'yt:b', 'yt:a']);
    });

    test('a song played again moves up instead of appearing twice', () {
      final list = withRecorded([_e('c'), _e('b'), _e('a')], _e('a'));
      expect(_ids(list), ['yt:a', 'yt:c', 'yt:b']);
    });

    test('only the newest songs are kept', () {
      final list = withRecorded([_e('c'), _e('b'), _e('a')], _e('d'), limit: 3);
      expect(_ids(list), ['yt:d', 'yt:c', 'yt:b']);
    });

    test('the list it was given is not changed', () {
      final before = [_e('a')];
      withRecorded(before, _e('b'));
      expect(_ids(before), ['yt:a']);
    });
  });

  group('withoutEntry', () {
    test('takes out just that song', () {
      expect(_ids(withoutEntry([_e('c'), _e('b'), _e('a')], 'yt:b')),
          ['yt:c', 'yt:a']);
    });

    test('a song that is not there changes nothing', () {
      expect(_ids(withoutEntry([_e('a')], 'yt:zzz')), ['yt:a']);
    });
  });
}
