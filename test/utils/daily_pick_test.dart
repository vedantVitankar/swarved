import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/utils/daily_pick.dart';

void main() {
  group('dayNumber', () {
    test('every moment of one day gives the same number', () {
      expect(dayNumber(DateTime(2026, 10, 9, 0, 0)),
          dayNumber(DateTime(2026, 10, 9, 23, 59, 59)));
    });

    test('the next day is one more, across a month and a year', () {
      final oct31 = dayNumber(DateTime(2026, 10, 31));
      expect(dayNumber(DateTime(2026, 11, 1)), oct31 + 1);

      final dec31 = dayNumber(DateTime(2026, 12, 31));
      expect(dayNumber(DateTime(2027, 1, 1)), dec31 + 1);
    });

    test('1 January 1970 is day zero', () {
      expect(dayNumber(DateTime(1970, 1, 1)), 0);
    });
  });

  group('pickBySeed', () {
    test('walks through the list and wraps around', () {
      const items = ['a', 'b', 'c'];
      expect([for (var i = 0; i < 7; i++) pickBySeed(items, i)],
          ['a', 'b', 'c', 'a', 'b', 'c', 'a']);
    });

    test('an empty list gives null', () {
      expect(pickBySeed(<String>[], 3), isNull);
    });

    test('the same seed always gives the same item', () {
      const items = ['a', 'b', 'c'];
      expect(pickBySeed(items, 20000), pickBySeed(items, 20000));
    });

    test('a negative seed still lands inside the list', () {
      expect(pickBySeed(const ['a', 'b', 'c'], -1), 'c');
    });
  });

  group('seedFromText', () {
    test('is steady for the same text', () {
      expect(seedFromText('Kesariya'), seedFromText('Kesariya'));
    });

    test('differs between different texts', () {
      expect(seedFromText('Kesariya'), isNot(seedFromText('Tum Hi Ho')));
    });

    test('is never negative, even for long text', () {
      expect(seedFromText('yt:' * 500), greaterThanOrEqualTo(0));
      expect(seedFromText(''), 0);
    });
  });
}
