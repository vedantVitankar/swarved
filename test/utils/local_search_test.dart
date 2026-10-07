import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/utils/local_search.dart';

Track _track(
  String title, {
  String artist = 'Unknown artist',
  String album = 'Album',
  String folder = 'Folder',
}) {
  return Track(
    filePath: '/music/$folder/$title.mp3',
    title: title,
    artist: artist,
    album: album,
    duration: const Duration(minutes: 3),
    folder: folder,
  );
}

void main() {
  final library = [
    _track('Kesariya', artist: 'Arijit Singh', folder: 'Slow dances'),
    _track('Tum Hi Ho', artist: 'Arijit Singh', folder: 'Rainy days'),
    _track('Channa Mereya', artist: 'Arijit Singh'),
    _track('Perfect', artist: 'Ed Sheeran'),
  ];

  group('searchLocal', () {
    test('an empty or blank query matches nothing', () {
      expect(searchLocal(library, ''), isEmpty);
      expect(searchLocal(library, '   '), isEmpty);
    });

    test('matches on the title, in any letter case', () {
      final found = searchLocal(library, 'KESAR');
      expect(found.map((t) => t.title), ['Kesariya']);
    });

    test('matches on the artist', () {
      final found = searchLocal(library, 'arijit');
      expect(found.length, 3);
    });

    test('every word has to match, in any order', () {
      final found = searchLocal(library, 'singh tum');
      expect(found.map((t) => t.title), ['Tum Hi Ho']);
    });

    test('matches on the folder name', () {
      final found = searchLocal(library, 'rainy');
      expect(found.map((t) => t.title), ['Tum Hi Ho']);
    });

    test('title matches come before artist-only matches', () {
      final mixed = [
        _track('Zzz', artist: 'Sheeran Fan Club'),
        _track('Sheeran Sings'),
      ];
      final found = searchLocal(mixed, 'sheeran');
      expect(found.map((t) => t.title), ['Sheeran Sings', 'Zzz']);
    });

    test('stops at the limit', () {
      final many = [for (var i = 0; i < 50; i++) _track('Love $i')];
      expect(searchLocal(many, 'love').length, kLocalResultLimit);
      expect(searchLocal(many, 'love', limit: 3).length, 3);
    });

    test('finds nothing when nothing matches', () {
      expect(searchLocal(library, 'zzzz'), isEmpty);
    });
  });
}
