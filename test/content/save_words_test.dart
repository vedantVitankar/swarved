import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/content/save_words.dart';
import 'package:swarved/models/save_problem.dart';

void main() {
  test('every save problem has a message', () {
    for (final problem in SaveProblem.values) {
      expect(SaveWords.forProblem(problem).trim(), isNotEmpty);
    }
  });
}
