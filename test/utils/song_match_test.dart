import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/song_note.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/utils/song_match.dart';

Track _local(String title, {String artist = 'Arijit Singh'}) => Track(
      filePath: '/music/$title.mp3',
      title: title,
      artist: artist,
      album: '',
      duration: const Duration(minutes: 3),
      folder: 'music',
    );

Track _youtube(String id) => Track.youtube(
      videoId: id,
      title: 'Anything',
      artist: 'Anyone',
      duration: const Duration(minutes: 3),
    );

void main() {
  group('songMatches', () {
    test('ignores case, spaces and punctuation in the title', () {
      const note = SongNote(title: 'tum hi ho', note: 'x');
      expect(songMatches(note, _local('Tum Hi Ho!')), isTrue);
    });

    test('a different title does not match', () {
      const note = SongNote(title: 'Tum Hi Ho', note: 'x');
      expect(songMatches(note, _local('Kesariya')), isFalse);
    });

    test('an empty artist matches any artist', () {
      const note = SongNote(title: 'Kesariya', note: 'x');
      expect(songMatches(note, _local('Kesariya', artist: 'Someone')), isTrue);
    });

    test('a named artist must match too', () {
      const note =
          SongNote(title: 'Kesariya', artist: 'Arijit Singh', note: 'x');
      expect(songMatches(note, _local('Kesariya')), isTrue);
      expect(songMatches(note, _local('Kesariya', artist: 'Cover')), isFalse);
    });

    test('an id decides alone and matches YouTube songs', () {
      const note = SongNote(id: 'yt:abc', title: 'Ignored', note: 'x');
      expect(songMatches(note, _youtube('abc')), isTrue);
      expect(songMatches(note, _youtube('zzz')), isFalse);
    });

    test('works with non-Latin titles', () {
      const note = SongNote(title: 'तुम ही हो', note: 'x');
      expect(songMatches(note, _local('तुम ही हो')), isTrue);
    });

    test('vowel signs are kept, so different Hindi titles stay different', () {
      expect(normalizeForMatch('तुम'), isNot(normalizeForMatch('तम')));
      const note = SongNote(title: 'तुम', note: 'x');
      expect(songMatches(note, _local('तम')), isFalse);
    });
  });

  group('titleMatches', () {
    test('matches on title alone when no artist is given', () {
      expect(titleMatches(_local('Tum Hi Ho!'), title: 'tum hi ho'), isTrue);
      expect(titleMatches(_local('Kesariya'), title: 'Tum Hi Ho'), isFalse);
    });

    test('an empty title never matches', () {
      expect(titleMatches(_local('Kesariya'), title: ''), isFalse);
      expect(titleMatches(_local('Kesariya'), title: '  !! '), isFalse);
    });

    test('a given artist must match too', () {
      final track = _local('Kesariya');
      expect(titleMatches(track, title: 'Kesariya', artist: 'arijit singh'),
          isTrue);
      expect(titleMatches(track, title: 'Kesariya', artist: 'Cover'), isFalse);
    });
  });
}
