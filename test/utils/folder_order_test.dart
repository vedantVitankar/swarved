import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/utils/folder_order.dart';

List<Track> _tracks(String folder) => [
      Track(
        filePath: '/music/$folder/a.mp3',
        title: 'a',
        artist: 'Artist',
        album: 'Album',
        duration: const Duration(minutes: 3),
        folder: folder,
      ),
    ];

void main() {
  group('sortedFolders', () {
    test('sorts A to Z ignoring case', () {
      final sorted = sortedFolders({
        'banana': _tracks('banana'),
        'Cherry': _tracks('Cherry'),
        'apple': _tracks('apple'),
      });

      expect(sorted.map((e) => e.key).toList(), ['apple', 'banana', 'Cherry']);
    });

    test('names differing only by case keep a fixed order', () {
      final sorted = sortedFolders({
        'rain': _tracks('rain'),
        'Rain': _tracks('Rain'),
      });

      expect(sorted.map((e) => e.key).toList(), ['Rain', 'rain']);
    });

    test('keeps each folder with its own songs', () {
      final sorted = sortedFolders({'b': _tracks('b'), 'a': _tracks('a')});

      expect(sorted.first.value.single.folder, 'a');
    });

    test('an empty library gives an empty list', () {
      expect(sortedFolders({}), isEmpty);
    });
  });
}
