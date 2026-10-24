import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/content/words.dart';

void main() {
  group('Words.greeting oneLine', () {
    test('turns the break into a space', () {
      expect(
        Words.greeting(DateTime(2026, 10, 5, 8), oneLine: true),
        'Good morning, Swarnima',
      );
      expect(
        Words.greeting(DateTime(2026, 10, 5, 13), oneLine: true),
        'Hey, Swara',
      );
      expect(
        Words.greeting(DateTime(2026, 10, 5, 19), oneLine: true),
        'Good evening, Swara',
      );
      expect(
        Words.greeting(DateTime(2026, 10, 5, 23), oneLine: true),
        'Still up, baby?',
      );
    });

    test('keeps the break by default', () {
      expect(Words.greeting(DateTime(2026, 10, 5, 8)), 'Good morning,\nSwarnima');
    });
  });

  group('On this day words', () {
    test('one year is singular', () {
      expect(Words.onThisDayWhen(1), 'A year ago today');
    });

    test('more years are plural', () {
      expect(Words.onThisDayWhen(3), '3 years ago today');
    });

    test('a song names the artist when there is one', () {
      expect(Words.onThisDaySong('Kesariya', 'Arijit'),
          'You played Kesariya, Arijit.');
      expect(Words.onThisDaySong('Kesariya', ''), 'You played Kesariya.');
    });
  });
}
