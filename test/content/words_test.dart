import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/content/words.dart';

void main() {
  group('Words.greeting', () {
    String at(int hour, [int minute = 0]) =>
        Words.greeting(DateTime(2026, 10, 5, hour, minute));

    test('morning runs from 5:00 to 11:59', () {
      expect(at(5), 'Good morning, Swarnima');
      expect(at(11, 59), 'Good morning, Swarnima');
    });

    test('afternoon runs from 12:00 to 16:59', () {
      expect(at(12), 'Hey, Swara');
      expect(at(16, 59), 'Hey, Swara');
    });

    test('evening runs from 17:00 to 21:59', () {
      expect(at(17), 'Good evening, Swara');
      expect(at(21, 59), 'Good evening, Swara');
    });

    test('late night runs from 22:00 to 4:59', () {
      expect(at(22), 'Still up, baby?');
      expect(at(0), 'Still up, baby?');
      expect(at(4, 59), 'Still up, baby?');
    });
  });
}
