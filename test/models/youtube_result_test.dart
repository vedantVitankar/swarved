import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/track_source.dart';
import 'package:swarved/models/youtube_result.dart';

void main() {
  group('YoutubeResult.tryParse', () {
    test('reads a full entry', () {
      final result = YoutubeResult.tryParse({
        'id': 'sJV8kbT1MEU',
        'title': ' Kesariya ',
        'artist': 'Arijit Singh',
        'durationSeconds': 268,
        'thumbnailUrl': 'https://example.com/a.jpg',
      })!;

      expect(result.id, 'sJV8kbT1MEU');
      expect(result.title, 'Kesariya');
      expect(result.artist, 'Arijit Singh');
      expect(result.duration, const Duration(seconds: 268));
      expect(result.thumbnailUrl, 'https://example.com/a.jpg');
    });

    test('missing artist, duration and thumbnail are allowed', () {
      final result = YoutubeResult.tryParse({
        'id': 'abc',
        'title': 'Song',
        'artist': null,
        'durationSeconds': null,
        'thumbnailUrl': null,
      })!;

      expect(result.artist, '');
      expect(result.duration, isNull);
      expect(result.thumbnailUrl, isNull);
    });

    test('an entry without an id or title is unusable', () {
      expect(YoutubeResult.tryParse({'title': 'No id'}), isNull);
      expect(YoutubeResult.tryParse({'id': '', 'title': 'Empty id'}), isNull);
      expect(YoutubeResult.tryParse({'id': 'abc'}), isNull);
      expect(YoutubeResult.tryParse({'id': 'abc', 'title': '  '}), isNull);
      expect(YoutubeResult.tryParse('not a map'), isNull);
      expect(YoutubeResult.tryParse(null), isNull);
    });
  });

  group('YoutubeResult.parseList', () {
    test('reads the results list', () {
      final list = YoutubeResult.parseList({
        'results': [
          {'id': 'a', 'title': 'One'},
          {'id': 'b', 'title': 'Two'},
        ],
      });

      expect(list.map((r) => r.id), ['a', 'b']);
    });

    test('skips unusable entries and repeated ids', () {
      final list = YoutubeResult.parseList({
        'results': [
          {'id': 'a', 'title': 'One'},
          {'title': 'No id'},
          {'id': 'a', 'title': 'One again'},
          'junk',
        ],
      });

      expect(list.map((r) => r.id), ['a']);
    });

    test('an empty results list is fine', () {
      expect(YoutubeResult.parseList({'results': []}), isEmpty);
    });

    test('a wrong shape throws FormatException', () {
      expect(() => YoutubeResult.parseList([]), throwsFormatException);
      expect(() => YoutubeResult.parseList({}), throwsFormatException);
      expect(
        () => YoutubeResult.parseList({'results': 'nope'}),
        throwsFormatException,
      );
    });
  });

  group('YoutubeResult.toTrack', () {
    test('becomes a YouTube track identified by its video id', () {
      const result = YoutubeResult(
        id: 'abc',
        title: 'Song',
        artist: 'Singer',
        duration: Duration(seconds: 90),
        thumbnailUrl: 'https://example.com/a.jpg',
      );

      final track = result.toTrack();

      expect(track.source, TrackSource.youtube);
      expect(track.id, 'yt:abc');
      expect(track.filePath, '');
      expect(track.duration, const Duration(seconds: 90));
      expect(track.artworkUrl, 'https://example.com/a.jpg');
    });

    test('an unknown length becomes zero', () {
      const result = YoutubeResult(id: 'abc', title: 'Song', artist: '');
      expect(result.toTrack().duration, Duration.zero);
    });
  });
}
