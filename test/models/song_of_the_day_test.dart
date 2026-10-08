import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/song_of_the_day.dart';
import 'package:swarved/models/track.dart';

Track _local(String title, {String artist = 'Arijit Singh'}) => Track(
      filePath: '/music/$title.mp3',
      title: title,
      artist: artist,
      album: '',
      duration: const Duration(minutes: 3),
      folder: 'music',
    );

void main() {
  group('SongOfTheDay.tryParse', () {
    test('a library song needs only a title', () {
      final pick = SongOfTheDay.tryParse({'title': 'Kesariya'});

      expect(pick, isNotNull);
      expect(pick!.title, 'Kesariya');
      expect(pick.id, isNull);
      expect(pick.artist, '');
      expect(pick.label, isNull);
      expect(pick.note, isNull);
    });

    test('reads every field of a YouTube song', () {
      final pick = SongOfTheDay.tryParse({
        'id': 'yt:abc123',
        'title': 'How Bad',
        'artist': 'Asal',
        'durationSeconds': 215.6,
        'thumbnailUrl': 'https://example.com/art.jpg',
        'label': 'For you, Precious',
        'note': 'Listen to this one twice.',
      });

      expect(pick!.id, 'yt:abc123');
      expect(pick.title, 'How Bad');
      expect(pick.artist, 'Asal');
      expect(pick.duration, const Duration(seconds: 216));
      expect(pick.thumbnailUrl, 'https://example.com/art.jpg');
      expect(pick.label, 'For you, Precious');
      expect(pick.note, 'Listen to this one twice.');
    });

    test('trims text and treats blank optional fields as missing', () {
      final pick = SongOfTheDay.tryParse({
        'title': '  Kesariya  ',
        'label': '   ',
        'note': '',
        'thumbnailUrl': ' ',
      });

      expect(pick!.title, 'Kesariya');
      expect(pick.label, isNull);
      expect(pick.note, isNull);
      expect(pick.thumbnailUrl, isNull);
    });

    test('without a title there is no song of the day', () {
      expect(SongOfTheDay.tryParse({'note': 'Only a note'}), isNull);
      expect(SongOfTheDay.tryParse({'id': 'yt:abc', 'title': ' '}), isNull);
    });

    test('an id that is not a yt: id is rejected', () {
      expect(SongOfTheDay.tryParse({'id': 'abc', 'title': 'T'}), isNull);
      expect(SongOfTheDay.tryParse({'id': 'yt:', 'title': 'T'}), isNull);
    });

    test('something that is not an object is rejected', () {
      expect(SongOfTheDay.tryParse(null), isNull);
      expect(SongOfTheDay.tryParse('Kesariya'), isNull);
      expect(SongOfTheDay.tryParse(['Kesariya']), isNull);
    });

    test('a zero or odd length is ignored, not an error', () {
      expect(
        SongOfTheDay.tryParse({'title': 'T', 'durationSeconds': 0})!.duration,
        isNull,
      );
      expect(
        SongOfTheDay.tryParse({'title': 'T', 'durationSeconds': 'soon'})!
            .duration,
        isNull,
      );
    });
  });

  group('SongOfTheDay.resolve', () {
    test('finds a library song by title, ignoring case and punctuation', () {
      final tum = _local('Tum Hi Ho!');
      final library = [_local('Kesariya'), tum];

      expect(
        const SongOfTheDay(title: 'tum hi ho').resolve(library),
        same(tum),
      );
    });

    test('a named artist must match too', () {
      final cover = _local('Kesariya', artist: 'Cover');
      final original = _local('Kesariya');
      final library = [cover, original];

      expect(
        const SongOfTheDay(title: 'Kesariya', artist: 'Arijit Singh')
            .resolve(library),
        same(original),
      );
    });

    test('is null when the library does not have the song', () {
      const pick = SongOfTheDay(title: 'Kesariya');
      expect(pick.resolve([_local('Other')]), isNull);
      expect(pick.resolve([]), isNull);
    });

    test('a YouTube song becomes a YouTube track, whatever the library holds',
        () {
      final track = const SongOfTheDay(
        id: 'yt:abc123',
        title: 'How Bad',
        artist: 'Asal',
        duration: Duration(minutes: 3, seconds: 35),
        thumbnailUrl: 'https://example.com/art.jpg',
      ).resolve([_local('How Bad', artist: 'Asal')])!;

      expect(track.isLocal, isFalse);
      expect(track.id, 'yt:abc123');
      expect(track.videoId, 'abc123');
      expect(track.title, 'How Bad');
      expect(track.artist, 'Asal');
      expect(track.duration, const Duration(minutes: 3, seconds: 35));
      expect(track.artworkUrl, 'https://example.com/art.jpg');
    });

    test('a YouTube song without a length gets a zero length', () {
      final track = const SongOfTheDay(id: 'yt:abc', title: 'T').resolve([])!;
      expect(track.duration, Duration.zero);
      expect(track.artworkUrl, isNull);
    });
  });
}
