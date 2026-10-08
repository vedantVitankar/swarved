import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:swarved/models/save_problem.dart';
import 'package:swarved/services/song_writer.dart';

void main() {
  late Directory root;
  late Directory library;
  late File source;

  setUp(() {
    root = Directory.systemTemp.createTempSync('swarved_writer_test');
    library = Directory(p.join(root.path, 'library'))..createSync();
    source = File(p.join(root.path, 'incoming.part'))
      ..writeAsBytesSync([1, 2, 3, 4, 5]);
  });

  tearDown(() {
    root.deleteSync(recursive: true);
  });

  Matcher throwsProblem(SaveProblem problem) => throwsA(
        isA<SongWriteException>().having((e) => e.problem, 'problem', problem),
      );

  List<String> namesIn(Directory dir) =>
      dir.listSync().map((e) => p.basename(e.path)).toList()..sort();

  group('DirectSongWriter.write', () {
    test('puts the song in the folder under its name', () async {
      final path = await const DirectSongWriter()
          .write(source: source, folder: library, fileName: 'A - B.mp3');

      expect(path, p.join(library.path, 'A - B.mp3'));
      expect(File(path).readAsBytesSync(), [1, 2, 3, 4, 5]);
    });

    test('leaves no temporary file behind', () async {
      await const DirectSongWriter()
          .write(source: source, folder: library, fileName: 'A - B.mp3');

      expect(namesIn(library), ['A - B.mp3']);
    });

    test('leaves the source file for the caller to remove', () async {
      await const DirectSongWriter()
          .write(source: source, folder: library, fileName: 'A - B.mp3');

      expect(source.existsSync(), isTrue);
    });

    test('a taken name gets a number, and the other file is untouched',
        () async {
      File(p.join(library.path, 'A - B.mp3')).writeAsBytesSync([9, 9]);

      final path = await const DirectSongWriter()
          .write(source: source, folder: library, fileName: 'A - B.mp3');

      expect(path, p.join(library.path, 'A - B (2).mp3'));
      expect(File(p.join(library.path, 'A - B.mp3')).readAsBytesSync(), [9, 9]);
      expect(File(path).readAsBytesSync(), [1, 2, 3, 4, 5]);
    });

    test('keeps counting when several names are taken', () async {
      File(p.join(library.path, 'A - B.mp3')).writeAsBytesSync([9]);
      File(p.join(library.path, 'A - B (2).mp3')).writeAsBytesSync([9]);

      final path = await const DirectSongWriter()
          .write(source: source, folder: library, fileName: 'A - B.mp3');

      expect(path, p.join(library.path, 'A - B (3).mp3'));
    });

    test('a folder that is gone is reported, and nothing is created', () async {
      final gone = Directory(p.join(root.path, 'missing'));

      await expectLater(
        const DirectSongWriter()
            .write(source: source, folder: gone, fileName: 'A - B.mp3'),
        throwsProblem(SaveProblem.folderMissing),
      );
      expect(gone.existsSync(), isFalse);
    });

    test('a missing source file is reported, and nothing is written', () async {
      source.deleteSync();

      await expectLater(
        const DirectSongWriter()
            .write(source: source, folder: library, fileName: 'A - B.mp3'),
        throwsProblem(SaveProblem.unexpected),
      );
      expect(namesIn(library), isEmpty);
    });

    test('removes an abandoned temporary file, but not a fresh one', () async {
      final stale =
          File(p.join(library.path, '.Old.mp3${DirectSongWriter.partSuffix}'))
            ..writeAsBytesSync([1])
            ..setLastModifiedSync(
                DateTime.now().subtract(const Duration(hours: 1)));
      final fresh =
          File(p.join(library.path, '.New.mp3${DirectSongWriter.partSuffix}'))
            ..writeAsBytesSync([1]);

      await const DirectSongWriter()
          .write(source: source, folder: library, fileName: 'A - B.mp3');

      expect(stale.existsSync(), isFalse);
      expect(fresh.existsSync(), isTrue);
    });

    test('never touches the listener\'s own files', () async {
      final mine = File(p.join(library.path, 'notes.txt'))
        ..writeAsStringSync('hello')
        ..setLastModifiedSync(DateTime.now().subtract(const Duration(days: 9)));

      await const DirectSongWriter()
          .write(source: source, folder: library, fileName: 'A - B.mp3');

      expect(mine.existsSync(), isTrue);
    });
  });

  group('problemForFileError', () {
    FileSystemException error(int code) =>
        FileSystemException('x', '/p', OSError('x', code));

    test('a full device is told apart from other errors', () {
      for (final code in [28, 122, 112]) {
        expect(problemForFileError(error(code)), SaveProblem.diskFull,
            reason: 'code $code');
      }
    });

    test('a refused write is told apart', () {
      for (final code in [1, 13, 30, 5, 19]) {
        expect(problemForFileError(error(code)), SaveProblem.cannotWrite,
            reason: 'code $code');
      }
    });

    test('a vanished folder is told apart', () {
      for (final code in [2, 3]) {
        expect(problemForFileError(error(code)), SaveProblem.folderMissing,
            reason: 'code $code');
      }
    });

    test('a permission error without a code still reads as a refused write',
        () {
      expect(
        problemForFileError(const PathAccessException('/p', OSError('x', 0))),
        SaveProblem.cannotWrite,
      );
    });

    test('anything else is unexpected', () {
      expect(problemForFileError(error(999)), SaveProblem.unexpected);
      expect(problemForFileError(const FileSystemException('x')),
          SaveProblem.unexpected);
    });
  });
}
