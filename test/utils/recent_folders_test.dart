import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/utils/recent_folders.dart';

Track _song(String folder, String name) => Track(
      filePath: '/music/$folder/$name.mp3',
      title: name,
      artist: 'Artist',
      album: '',
      duration: const Duration(seconds: 100),
      folder: folder,
    );

Map<String, List<Track>> _library() => {
      'Slow dances': [_song('Slow dances', 'a'), _song('Slow dances', 'b')],
      'Rainy days': [_song('Rainy days', 'c')],
      'Road trip': [
        _song('Road trip', 'd'),
        _song('Road trip', 'e'),
        _song('Road trip', 'f'),
      ],
    };

void main() {
  group('foldersByRecency', () {
    test('puts the folder played last first', () {
      final library = _library();
      final order = foldersByRecency(library, [
        '/music/Rainy days/c.mp3',
        '/music/Slow dances/a.mp3',
      ]);
      expect(order.take(2), ['Rainy days', 'Slow dances']);
    });

    test('lists a folder once however often it was played', () {
      final library = _library();
      final order = foldersByRecency(library, [
        '/music/Slow dances/a.mp3',
        '/music/Slow dances/b.mp3',
        '/music/Slow dances/a.mp3',
      ]);
      expect(order.where((f) => f == 'Slow dances'), hasLength(1));
      expect(order, hasLength(3));
    });

    test('follows with unplayed folders, the biggest first', () {
      final library = _library();
      final order = foldersByRecency(library, ['/music/Rainy days/c.mp3']);
      expect(order, ['Rainy days', 'Road trip', 'Slow dances']);
    });

    test('breaks a tie in size by name', () {
      final library = {
        'B': [_song('B', 'x')],
        'A': [_song('A', 'y')],
      };
      expect(foldersByRecency(library, const []), ['A', 'B']);
    });

    test('skips songs that are in no folder', () {
      final library = _library();
      final order = foldersByRecency(library, [
        'yt:abc123',
        '/elsewhere/gone.mp3',
        '/music/Road trip/d.mp3',
      ]);
      expect(order.first, 'Road trip');
      expect(order, hasLength(3));
    });

    test('is empty with no folders', () {
      expect(foldersByRecency({}, ['yt:abc']), isEmpty);
    });
  });
}
