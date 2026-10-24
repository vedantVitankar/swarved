import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/content/save_words.dart';
import 'package:swarved/models/save_problem.dart';
import 'package:swarved/models/batch_result.dart';

void main() {
  test('every save problem has a message', () {
    for (final problem in SaveProblem.values) {
      expect(SaveWords.forProblem(problem).trim(), isNotEmpty);
    }
  });

  group('forBatch', () {
    test('says how many songs went into which folder', () {
      const result = BatchResult(folderName: 'Slow dances', saved: 3);

      expect(SaveWords.forBatch(result), 'Saved 3 songs to “Slow dances”.');
    });

    test('says when some songs could not be saved', () {
      const result = BatchResult(folderName: 'Mix', saved: 1, failed: 2);

      final message = SaveWords.forBatch(result);

      expect(message, contains('Saved 1 song to “Mix”.'));
      expect(message, contains('2 songs couldn’t be saved'));
    });

    test('says when there was nothing to download', () {
      const result = BatchResult(folderName: 'Mix', alreadySaved: 4);

      expect(SaveWords.forBatch(result), 'Everything here is already saved.');
    });

    test('says why the run stopped, after what did get saved', () {
      const result = BatchResult(
        folderName: 'Mix',
        saved: 2,
        stoppedBy: SaveProblem.diskFull,
      );

      expect(
        SaveWords.forBatch(result),
        'Saved 2 songs to “Mix”. ${SaveWords.forProblem(SaveProblem.diskFull)}',
      );
    });

    test('says why the run stopped when nothing was saved', () {
      const result = BatchResult(
        folderName: 'Mix',
        stoppedBy: SaveProblem.noToken,
      );

      expect(
        SaveWords.forBatch(result),
        SaveWords.forProblem(SaveProblem.noToken),
      );
    });

    test('says when she stopped it', () {
      expect(
        SaveWords.forBatch(
            const BatchResult(folderName: 'Mix', cancelled: true)),
        'Stopped.',
      );
      expect(
        SaveWords.forBatch(
          const BatchResult(folderName: 'Mix', saved: 1, cancelled: true),
        ),
        'Stopped. 1 song saved to “Mix”.',
      );
    });
  });

  test('the progress line never counts past the total', () {
    expect(SaveWords.downloadingProgress(0, 5), 'Downloading 1 of 5');
    expect(SaveWords.downloadingProgress(4, 5), 'Downloading 5 of 5');
    expect(SaveWords.downloadingProgress(5, 5), 'Downloading 5 of 5');
  });
}
