import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/widgets/folder_art.dart';

void main() {
  group('FolderArt.paletteIndex', () {
    test('a name always gets the same colour', () {
      expect(FolderArt.paletteIndex('Slow dances'),
          FolderArt.paletteIndex('Slow dances'));
    });

    test('known folders keep their colours across releases', () {
      expect(FolderArt.paletteIndex('Slow dances'), 1);
      expect(FolderArt.paletteIndex('Rainy days'), 2);
      expect(FolderArt.paletteIndex('Mornings'), 0);
      expect(FolderArt.paletteIndex('Late night'), 4);
    });

    test('the index always lands inside the palette', () {
      for (final name in [
        '',
        'Music',
        'Road trip',
        'A very long folder name'
      ]) {
        expect(FolderArt.paletteIndex(name), inInclusiveRange(0, 4));
      }
    });
  });
}
