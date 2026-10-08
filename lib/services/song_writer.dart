import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/save_problem.dart';
import '../utils/song_file_name.dart';

/// A song could not be written into the folder.
class SongWriteException implements Exception {
  const SongWriteException(this.problem);

  final SaveProblem problem;

  @override
  String toString() => 'SongWriteException($problem)';
}

/// Puts a finished song file into the library folder.
abstract interface class SongWriter {
  /// Copies [source] into [folder] under [fileName], or a numbered variant
  /// when that name is taken by another file. Returns the path it ended up
  /// at. Throws [SongWriteException].
  Future<String> write({
    required File source,
    required Directory folder,
    required String fileName,
  });
}

/// Writes with plain dart:io. Measured to work on Android 9 and older (with
/// the write permission in the manifest) and expected to work on Windows.
/// Android 10 and newer need a different writer.
///
/// The song is copied under a hidden temporary name and renamed when it is
/// complete, so the library never sees half a song.
class DirectSongWriter implements SongWriter {
  const DirectSongWriter();

  /// Ends the hidden temporary file. The library scanner ignores it.
  static const partSuffix = '.swarved-part';

  /// A leftover temporary file this old was abandoned by a crash.
  static const _staleAfter = Duration(minutes: 10);

  @override
  Future<String> write({
    required File source,
    required Directory folder,
    required String fileName,
  }) async {
    if (!await folder.exists()) {
      throw const SongWriteException(SaveProblem.folderMissing);
    }
    if (!await source.exists()) {
      throw const SongWriteException(SaveProblem.unexpected);
    }

    File? part;
    try {
      await _removeStaleParts(folder);
      final target = await _freeName(folder, fileName);
      part = File(p.join(folder.path, '.${p.basename(target)}$partSuffix'));
      await source.copy(part.path);
      await part.rename(target);
      return target;
    } on FileSystemException catch (e) {
      throw SongWriteException(problemForFileError(e));
    } finally {
      await _deleteQuietly(part);
    }
  }

  Future<String> _freeName(Directory folder, String fileName) async {
    for (var number = 1; number <= 99; number++) {
      final name = number == 1 ? fileName : numberedFileName(fileName, number);
      final path = p.join(folder.path, name);
      if (!await File(path).exists()) return path;
    }
    throw const SongWriteException(SaveProblem.unexpected);
  }

  Future<void> _removeStaleParts(Directory folder) async {
    try {
      await for (final entity in folder.list(followLinks: false)) {
        if (entity is! File || !entity.path.endsWith(partSuffix)) continue;
        final age = DateTime.now().difference(await entity.lastModified());
        if (age >= _staleAfter) await _deleteQuietly(entity);
      }
    } catch (_) {
      // Housekeeping only: never let it stop a save.
    }
  }

  Future<void> _deleteQuietly(File? file) async {
    if (file == null) return;
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Tidying up only: nothing to do if it fails.
    }
  }
}

/// Tells apart the file errors a listener can act on. The numbers are the
/// operating system's own: Android and Linux on the first line of each
/// group, Windows on the second.
SaveProblem problemForFileError(FileSystemException error) {
  switch (error.osError?.errorCode) {
    case 28: // no space left on device
    case 122: // disk quota exceeded
    case 112: // Windows: disk full
      return SaveProblem.diskFull;
    case 2: // no such file or directory
    case 3: // Windows: path not found
      return SaveProblem.folderMissing;
    case 1: // operation not permitted
    case 13: // permission denied
    case 30: // read-only file system
    case 5: // Windows: access denied
    case 19: // Windows: write protected
      return SaveProblem.cannotWrite;
  }
  return error is PathAccessException
      ? SaveProblem.cannotWrite
      : SaveProblem.unexpected;
}
