import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/content/playback_words.dart';
import 'package:swarved/models/playback_problem.dart';

void main() {
  group('PlaybackWords.forProblem', () {
    test('every problem has a message', () {
      for (final problem in PlaybackProblem.values) {
        expect(PlaybackWords.forProblem(problem).trim(), isNotEmpty);
      }
    });

    test('messages stay short enough for the mini player\'s single line', () {
      for (final problem in PlaybackProblem.values) {
        expect(
          PlaybackWords.forProblem(problem).length,
          lessThanOrEqualTo(40),
          reason: '$problem is too long for one line',
        );
      }
    });
  });
}
