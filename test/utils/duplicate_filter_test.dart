import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/models/youtube_result.dart';
import 'package:swarved/utils/duplicate_filter.dart';

Track _local(String title, String artist) => Track(
      filePath: '/music/$title.mp3',
      title: title,
      artist: artist,
      album: 'Album',
      duration: const Duration(minutes: 3),
      folder: 'Folder',
    );

YoutubeResult _result(String id, String title, String artist) =>
    YoutubeResult(id: id, title: title, artist: artist);

void main() {
  group('withoutLocalDuplicates', () {
    test('hides a result with the same title and artist', () {
      final library = [_local('Kesariya', 'Arijit Singh')];
      final results = [_result('a', 'Kesariya', 'Arijit Singh')];

      expect(withoutLocalDuplicates(results, library), isEmpty);
    });

    test('ignores letter case, punctuation and bracketed extras', () {
      final library = [_local('Kesariya', 'Arijit Singh')];
      final results = [
        _result('a', 'KESARIYA (From "Brahmastra")', 'Arijit Singh'),
        _result('b', 'kesariya [Official Audio]', 'arijit singh'),
      ];

      expect(withoutLocalDuplicates(results, library), isEmpty);
    });

    test('an artist list that contains the local artist still matches', () {
      final library = [_local('Kesariya', 'Arijit Singh')];
      final results = [_result('a', 'Kesariya', 'Arijit Singh, Pritam')];

      expect(withoutLocalDuplicates(results, library), isEmpty);
    });

    test('keeps a result by a different artist', () {
      final library = [_local('Perfect', 'Ed Sheeran')];
      final results = [_result('a', 'Perfect', 'Someone Else')];

      expect(withoutLocalDuplicates(results, library), results);
    });

    test('keeps a different version of the song', () {
      final library = [_local('Kesariya', 'Arijit Singh')];
      final results = [
        _result('a', 'Kesariya (Live)', 'Arijit Singh'),
        _result('b', 'Kesariya - Remix', 'Arijit Singh'),
        _result('c', 'Kesariya Reprise', 'Arijit Singh'),
      ];

      expect(withoutLocalDuplicates(results, library), results);
    });

    test('keeps everything when the local artist is unknown', () {
      final library = [_local('Kesariya', 'Unknown artist')];
      final results = [_result('a', 'Kesariya', 'Arijit Singh')];

      expect(withoutLocalDuplicates(results, library), results);
    });

    test('keeps a result with no artist', () {
      final library = [_local('Kesariya', 'Arijit Singh')];
      final results = [_result('a', 'Kesariya', '')];

      expect(withoutLocalDuplicates(results, library), results);
    });

    test('matches Hindi titles', () {
      final library = [_local('तुम ही हो', 'अरिजीत सिंह')];
      final results = [_result('a', 'तुम ही हो', 'अरिजीत सिंह')];

      expect(withoutLocalDuplicates(results, library), isEmpty);
    });

    test('returns the results untouched for an empty library', () {
      final results = [_result('a', 'Kesariya', 'Arijit Singh')];

      expect(withoutLocalDuplicates(results, const []), results);
    });
  });
}
