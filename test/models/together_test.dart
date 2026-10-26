import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/together.dart';

void main() {
  group('Together.parse', () {
    test('anything that is not a map is nothing', () {
      for (final bad in [null, 'x', 3, <Object>[]]) {
        final together = Together.parse(bad);
        expect(together.since, isNull);
        expect(together.meetingDate, isNull);
        expect(together.meetingLabel, '');
      }
    });

    test('reads the days and his words for the countdown', () {
      final together = Together.parse({
        'since': '2024-02-14',
        'meetingDate': '2026-12-25',
        'meetingLabel': '  Until I hold you ',
      });
      expect(together.since, DateTime(2024, 2, 14));
      expect(together.meetingDate, DateTime(2026, 12, 25));
      expect(together.meetingLabel, 'Until I hold you');
    });

    test('a day that does not exist is no day', () {
      final together = Together.parse({
        'since': '2024-02-30',
        'meetingDate': 'soon',
      });
      expect(together.since, isNull);
      expect(together.meetingDate, isNull);
    });
  });

  group('daysUntilMeeting', () {
    Together meeting(String day) => Together.parse({'meetingDate': day});

    test('counts whole days', () {
      expect(meeting('2026-12-25').daysUntilMeeting(DateTime(2026, 12, 13)), 12);
      expect(meeting('2026-12-25').daysUntilMeeting(DateTime(2026, 12, 24)), 1);
    });

    test('is 0 on the day itself, whatever the time', () {
      expect(
        meeting('2026-12-25').daysUntilMeeting(DateTime(2026, 12, 25, 23, 59)),
        0,
      );
      expect(
        meeting('2026-12-25').daysUntilMeeting(DateTime(2026, 12, 25, 0, 1)),
        0,
      );
    });

    test('is nothing once the day has passed', () {
      expect(meeting('2026-12-25').daysUntilMeeting(DateTime(2026, 12, 26)),
          isNull);
    });

    test('is nothing when there is no meeting day', () {
      expect(Together.none.daysUntilMeeting(DateTime(2026)), isNull);
    });

    test('is not thrown off by the clocks changing', () {
      // Clocks change on 29 March 2026 in much of Europe.
      expect(meeting('2026-04-01').daysUntilMeeting(DateTime(2026, 3, 28)), 4);
      expect(meeting('2026-11-02').daysUntilMeeting(DateTime(2026, 10, 24)), 9);
    });

    test('works across a year end', () {
      expect(meeting('2027-01-02').daysUntilMeeting(DateTime(2026, 12, 30)), 3);
    });
  });
}
