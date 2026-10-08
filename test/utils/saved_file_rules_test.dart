import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:swarved/utils/saved_file_rules.dart';

void main() {
  final root = p.join('storage', 'Music');
  final inside = p.join(root, 'Songs', 'A - B.mp3');

  group('shouldListSavedFile', () {
    test('lists an mp3 inside the library folder', () {
      expect(
        shouldListSavedFile(
            libraryRoot: root, filePath: inside, listedPaths: const []),
        isTrue,
      );
    });

    test('lists a file saved straight into the library folder', () {
      expect(
        shouldListSavedFile(
          libraryRoot: root,
          filePath: p.join(root, 'A - B.MP3'),
          listedPaths: const [],
        ),
        isTrue,
      );
    });

    test('skips everything when no library is open', () {
      expect(
        shouldListSavedFile(
            libraryRoot: null, filePath: inside, listedPaths: const []),
        isFalse,
      );
    });

    test('skips a file outside the library folder', () {
      expect(
        shouldListSavedFile(
          libraryRoot: root,
          filePath: p.join('storage', 'Downloads', 'A - B.mp3'),
          listedPaths: const [],
        ),
        isFalse,
      );
    });

    test('a folder with a similar name is not inside the library', () {
      expect(
        shouldListSavedFile(
          libraryRoot: root,
          filePath: p.join('storage', 'Music2', 'A - B.mp3'),
          listedPaths: const [],
        ),
        isFalse,
      );
    });

    test('skips anything that is not an mp3', () {
      expect(
        shouldListSavedFile(
          libraryRoot: root,
          filePath: p.join(root, 'A - B.mp3.swarved-part'),
          listedPaths: const [],
        ),
        isFalse,
      );
    });

    test('skips a file that is listed already', () {
      expect(
        shouldListSavedFile(
            libraryRoot: root, filePath: inside, listedPaths: [inside]),
        isFalse,
      );
    });
  });
}
