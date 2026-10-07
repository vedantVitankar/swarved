import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/utils/search_query.dart';

void main() {
  group('normalizeQuery', () {
    test('trims and collapses whitespace', () {
      expect(normalizeQuery('  arijit \t  singh \n'), 'arijit singh');
    });

    test('blank input becomes empty', () {
      expect(normalizeQuery('   '), '');
      expect(normalizeQuery(''), '');
    });

    test('keeps non-English text intact', () {
      expect(normalizeQuery('  तुम  ही हो '), 'तुम ही हो');
    });

    test('cuts to the server limit, counting characters', () {
      final long = 'a' * (kMaxQueryLength + 40);
      expect(normalizeQuery(long).runes.length, kMaxQueryLength);
    });

    test('leaves a query at exactly the limit alone', () {
      final exact = 'b' * kMaxQueryLength;
      expect(normalizeQuery(exact), exact);
    });
  });
}
