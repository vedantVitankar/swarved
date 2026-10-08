import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swarved/services/saved_songs_index.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SavedSongsIndex', () {
    test('starts empty', () async {
      final index = SavedSongsIndex(fileExists: (_) => true);
      await index.load();

      expect(index.isSaved('abc'), isFalse);
      expect(index.pathFor('abc'), isNull);
    });

    test('remembers a saved song across restarts', () async {
      final first = SavedSongsIndex(fileExists: (_) => true);
      await first.load();
      await first.record('abc', '/music/A - B.mp3');

      final second = SavedSongsIndex(fileExists: (_) => true);
      await second.load();

      expect(second.isSaved('abc'), isTrue);
      expect(second.pathFor('abc'), '/music/A - B.mp3');
    });

    test('a song whose file is gone counts as not saved', () async {
      var exists = true;
      final index = SavedSongsIndex(fileExists: (_) => exists);
      await index.load();
      await index.record('abc', '/music/A - B.mp3');
      expect(index.isSaved('abc'), isTrue);

      exists = false;

      expect(index.isSaved('abc'), isFalse);
      expect(index.pathFor('abc'), isNull);
    });

    test('forget removes a song', () async {
      final index = SavedSongsIndex(fileExists: (_) => true);
      await index.load();
      await index.record('abc', '/music/A.mp3');
      await index.forget('abc');

      expect(index.isSaved('abc'), isFalse);
    });

    test('tells listeners when something is recorded', () async {
      final index = SavedSongsIndex(fileExists: (_) => true);
      await index.load();
      var notified = 0;
      index.addListener(() => notified++);

      await index.record('abc', '/music/A.mp3');

      expect(notified, greaterThan(0));
    });

    test('damaged saved data starts an empty list instead of crashing',
        () async {
      SharedPreferences.setMockInitialValues({'saved_songs_v1': '{not json'});
      final index = SavedSongsIndex(fileExists: (_) => true);

      await index.load();

      expect(index.isSaved('abc'), isFalse);
    });

    test('entries of the wrong shape are skipped, good ones kept', () async {
      SharedPreferences.setMockInitialValues({
        'saved_songs_v1': '{"good":"/music/A.mp3","bad":5,"empty":""}',
      });
      final index = SavedSongsIndex(fileExists: (_) => true);

      await index.load();

      expect(index.isSaved('good'), isTrue);
      expect(index.isSaved('bad'), isFalse);
      expect(index.isSaved('empty'), isFalse);
    });
  });
}
