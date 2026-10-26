import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/letter.dart';

Map<String, Object?> valid([Map<String, Object?> change = const {}]) => {
      'id': 'abc12345',
      'when': ' you miss me ',
      'body': ' I am right here. ',
      ...change,
    };

void main() {
  group('Letter.tryParse', () {
    test('reads a letter and trims it', () {
      final letter = Letter.tryParse(valid())!;
      expect(letter.id, 'abc12345');
      expect(letter.when, 'you miss me');
      expect(letter.body, 'I am right here.');
      expect(letter.locked, isFalse);
      expect(letter.heading, 'Open when you miss me');
    });

    test('the heading is his title when there is no "when"', () {
      final letter = Letter.tryParse(valid({'when': '', 'title': 'For you'}))!;
      expect(letter.heading, 'For you');
    });

    test('it needs a "when" or a title', () {
      expect(Letter.tryParse(valid({'when': '', 'title': ''})), isNull);
    });

    test('it needs a proper id', () {
      for (final id in ['', 'abc', 'ABC12345', 'abc 1234', 'a' * 25, 5, null]) {
        expect(Letter.tryParse(valid({'id': id})), isNull, reason: '$id');
      }
    });

    test('anything that is not a map is not a letter', () {
      expect(Letter.tryParse(null), isNull);
      expect(Letter.tryParse('letter'), isNull);
      expect(Letter.tryParse([valid()]), isNull);
    });

    test('a letter that can be opened needs its words or a recording', () {
      expect(Letter.tryParse(valid({'body': ''})), isNull);
      expect(
        Letter.tryParse(valid({'body': '', 'voice': 'aaaaaaaaaaaaaaaa.mp3'})),
        isNotNull,
      );
    });

    test('a locked letter arrives without its words, and that is fine', () {
      final letter = Letter.tryParse({
        'id': 'abc12345',
        'when': 'you need a hug',
        'unlocksOn': '2026-12-25',
        'locked': true,
      })!;
      expect(letter.locked, isTrue);
      expect(letter.body, '');
      expect(letter.unlocksOn, DateTime(2026, 12, 25));
    });

    test('only uploaded files are kept as the photo and the recording', () {
      final letter = Letter.tryParse(valid({
        'photo': 'aaaaaaaaaaaaaaaa.jpg',
        'voice': 'bbbbbbbbbbbbbbbb.m4a',
      }))!;
      expect(letter.photo, 'aaaaaaaaaaaaaaaa.jpg');
      expect(letter.voice, 'bbbbbbbbbbbbbbbb.m4a');

      final bad = Letter.tryParse(valid({
        'photo': 'assets/x.jpg',
        'voice': 'bbbbbbbbbbbbbbbb.jpg',
      }))!;
      expect(bad.photo, isNull);
      expect(bad.voice, isNull);
    });

    test('a made-up unlock day is no day', () {
      expect(Letter.tryParse(valid({'unlocksOn': '2026-02-30'}))!.unlocksOn,
          isNull);
    });
  });
}
