import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/listen_entry.dart';
import 'package:swarved/models/memory.dart';
import 'package:swarved/utils/on_this_day.dart';

Memory _memory(int year, int month, int day, [String caption = 'Us.']) =>
    Memory(date: DateTime(year, month, day), caption: caption);

ListenEntry _played(DateTime at, [String title = 'Kesariya']) => ListenEntry(
      trackPath: '/music/$title.mp3',
      title: title,
      artist: 'Arijit',
      playedAt: at,
      listened: const Duration(minutes: 3),
    );

void main() {
  final today = DateTime(2026, 10, 24, 21, 30);

  group('pickOnThisDay', () {
    test('is null when there is nothing at all', () {
      expect(pickOnThisDay(today, memories: [], entries: []), isNull);
    });

    test('finds a memory from this date in an earlier year', () {
      final day = pickOnThisDay(
        today,
        memories: [_memory(2025, 10, 24, 'First call.')],
        entries: [],
      );
      expect(day?.yearsAgo, 1);
      expect(day?.memory?.caption, 'First call.');
      expect(day?.entry, isNull);
    });

    test('ignores other dates, and the same date this year', () {
      final day = pickOnThisDay(
        today,
        memories: [_memory(2025, 10, 23), _memory(2026, 10, 24)],
        entries: [_played(DateTime(2026, 10, 24, 8))],
      );
      expect(day, isNull);
    });

    test('the most recent year wins among memories', () {
      final day = pickOnThisDay(
        today,
        memories: [
          _memory(2023, 10, 24, 'Old.'),
          _memory(2025, 10, 24, 'Newer.'),
          _memory(2024, 10, 24, 'Middle.'),
        ],
        entries: [],
      );
      expect(day?.yearsAgo, 1);
      expect(day?.memory?.caption, 'Newer.');
    });

    test('his memory beats a song from the same date', () {
      final day = pickOnThisDay(
        today,
        memories: [_memory(2023, 10, 24)],
        entries: [_played(DateTime(2025, 10, 24, 22))],
      );
      expect(day?.memory, isNotNull);
      expect(day?.entry, isNull);
      expect(day?.yearsAgo, 3);
    });

    test('falls back to a song she played', () {
      final day = pickOnThisDay(
        today,
        memories: [_memory(2025, 3, 1)],
        entries: [_played(DateTime(2025, 10, 24, 22), 'Tum Hi Ho')],
      );
      expect(day?.memory, isNull);
      expect(day?.entry?.title, 'Tum Hi Ho');
      expect(day?.yearsAgo, 1);
    });

    test('the most recent play wins among songs', () {
      final day = pickOnThisDay(
        today,
        memories: [],
        entries: [
          _played(DateTime(2024, 10, 24, 9), 'Older'),
          _played(DateTime(2025, 10, 24, 9), 'Newer'),
          _played(DateTime(2025, 10, 24, 7), 'Earlier that day'),
        ],
      );
      expect(day?.entry?.title, 'Newer');
    });

    test('a leap day only comes round on a leap day', () {
      final memories = [_memory(2024, 2, 29)];
      expect(
        pickOnThisDay(DateTime(2028, 2, 29), memories: memories, entries: []),
        isNotNull,
      );
      expect(
        pickOnThisDay(DateTime(2027, 2, 28), memories: memories, entries: []),
        isNull,
      );
    });
  });
}
