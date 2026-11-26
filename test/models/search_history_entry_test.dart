import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/search_history_entry.dart';
import 'package:swarved/models/track.dart';

Track _youtube(String id, {String artist = 'Chan'}) => Track.youtube(
      videoId: id,
      title: 'Online $id',
      artist: artist,
      duration: const Duration(seconds: 125),
      artworkUrl: 'https://x/$id.jpg',
    );

Track _local(String path, {String folder = 'Music'}) => Track(
      filePath: path,
      title: 'Local song',
      artist: 'Her',
      album: 'Album',
      duration: const Duration(seconds: 200),
      folder: folder,
    );

void main() {
  group('SearchHistoryEntry', () {
    test('a YouTube song survives being written and read again', () {
      final entry = SearchHistoryEntry.fromTrack(_youtube('aaaaaaaaaaa'))!;
      final back = SearchHistoryEntry.tryParse(entry.toJson())!;
      final track = back.toTrack(const [])!;
      expect(track.id, 'yt:aaaaaaaaaaa');
      expect(track.title, 'Online aaaaaaaaaaa');
      expect(track.artist, 'Chan');
      expect(track.duration, const Duration(seconds: 125));
      expect(track.artworkUrl, 'https://x/aaaaaaaaaaa.jpg');
    });

    test('a local song is found again in the library by its id', () {
      final song = _local('/music/a.mp3');
      final entry = SearchHistoryEntry.fromTrack(song)!;
      expect(entry.toTrack([_local('/music/b.mp3'), song]), same(song));
    });

    test('a local song that left the library is not offered', () {
      final entry = SearchHistoryEntry.fromTrack(_local('/music/a.mp3'))!;
      expect(entry.toTrack([_local('/music/b.mp3')]), isNull);
      expect(entry.toTrack(const []), isNull);
    });

    test('a letter recording is never remembered', () {
      final recording = _local('/x/letters/1.m4a', folder: Track.letterRecordingFolder);
      expect(SearchHistoryEntry.fromTrack(recording), isNull);
    });

    test('an entry that cannot be understood is skipped', () {
      expect(SearchHistoryEntry.tryParse(null), isNull);
      expect(SearchHistoryEntry.tryParse('x'), isNull);
      expect(SearchHistoryEntry.tryParse({'id': '', 'title': 'T', 'local': true}), isNull);
      expect(SearchHistoryEntry.tryParse({'id': 'a', 'title': ' ', 'local': true}), isNull);
      expect(SearchHistoryEntry.tryParse({'id': 'yt:a', 'title': 'T', 'local': false}), isNull);
      expect(SearchHistoryEntry.tryParse({'id': 'a', 'title': 'T'}), isNull);
    });

    test('a missing artist and length are filled in quietly', () {
      final entry = SearchHistoryEntry.tryParse({
        'id': 'yt:abc',
        'local': false,
        'title': 'T',
        'videoId': 'abc',
      })!;
      expect(entry.artist, '');
      expect(entry.durationSeconds, 0);
      expect(entry.toTrack(const [])!.duration, Duration.zero);
    });
  });
}
