import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/content_pack.dart';
import 'package:swarved/models/memory.dart';
import 'package:swarved/utils/date_label.dart';

void main() {
  group('Memory.tryParse', () {
    test('reads the date, caption and photo', () {
      final memory = Memory.tryParse({
        'date': '2025-02-14',
        'caption': ' Our first walk. ',
        'image': 'assets/memories/walk.jpg',
      });
      expect(memory?.date, DateTime(2025, 2, 14));
      expect(memory?.caption, 'Our first walk.');
      expect(memory?.image, 'assets/memories/walk.jpg');
    });

    test('the photo is optional', () {
      final memory = Memory.tryParse({'date': '2025-02-14', 'caption': 'Hi'});
      expect(memory?.image, isNull);
    });

    test('a photo outside assets is ignored, the memory is kept', () {
      final memory = Memory.tryParse({
        'date': '2025-02-14',
        'caption': 'Hi',
        'image': 'https://example.com/a.jpg',
      });
      expect(memory?.caption, 'Hi');
      expect(memory?.image, isNull);
    });

    test('a missing caption or date is skipped', () {
      expect(Memory.tryParse({'date': '2025-02-14'}), isNull);
      expect(Memory.tryParse({'date': '2025-02-14', 'caption': ' '}), isNull);
      expect(Memory.tryParse({'caption': 'No date'}), isNull);
      expect(Memory.tryParse('nope'), isNull);
    });

    test('a date that does not exist is skipped, not rolled over', () {
      expect(Memory.tryParse({'date': '2025-02-30', 'caption': 'x'}), isNull);
      expect(Memory.tryParse({'date': '2025-13-01', 'caption': 'x'}), isNull);
      expect(Memory.tryParse({'date': '2025-00-10', 'caption': 'x'}), isNull);
    });

    test('only year-month-day is accepted', () {
      expect(Memory.parseDate('14/02/2025'), isNull);
      expect(Memory.parseDate('2025-2-14'), isNull);
      expect(Memory.parseDate('2025-02-14T10:00'), isNull);
      expect(Memory.parseDate(''), isNull);
    });

    test('29 February exists only in a leap year', () {
      expect(Memory.parseDate('2024-02-29'), DateTime(2024, 2, 29));
      expect(Memory.parseDate('2025-02-29'), isNull);
    });
  });

  group('Memory.inOrder', () {
    test('sorts oldest first and keeps written order within a day', () {
      final ordered = Memory.inOrder([
        Memory(date: DateTime(2025, 5, 1), caption: 'later'),
        Memory(date: DateTime(2024, 1, 1), caption: 'first'),
        Memory(date: DateTime(2025, 5, 1), caption: 'later too'),
      ]);
      expect(ordered.map((m) => m.caption), ['first', 'later', 'later too']);
    });
  });

  group('ContentPack memories', () {
    test('are read and ordered, bad ones skipped', () {
      final pack = ContentPack.parse('''
        {"memories": [
          {"date": "2025-06-01", "caption": "Second."},
          {"date": "2025-02-30", "caption": "Impossible."},
          {"date": "2024-12-25", "caption": "First."}
        ]}''');
      expect(pack.memories.map((m) => m.caption), ['First.', 'Second.']);
    });

    test('a missing or wrongly typed list is empty', () {
      expect(ContentPack.parse('{}').memories, isEmpty);
      expect(ContentPack.parse('{"memories": "x"}').memories, isEmpty);
    });
  });

  group('longDate', () {
    test('writes day, month name and year', () {
      expect(longDate(DateTime(2025, 2, 14)), '14 February 2025');
      expect(longDate(DateTime(2026, 1, 1)), '1 January 2026');
      expect(longDate(DateTime(2026, 12, 31)), '31 December 2026');
    });
  });

  group('Memory title and server photos', () {
    test('reads the title, trimmed, and keeps it apart from the caption', () {
      final memory = Memory.tryParse({
        'date': '2025-02-14',
        'title': '  Our first rain ',
        'caption': 'We got soaked.',
      });
      expect(memory?.title, 'Our first rain');
      expect(memory?.caption, 'We got soaked.');
    });

    test('the title is optional', () {
      final memory = Memory.tryParse({'date': '2025-02-14', 'caption': 'Hi'});
      expect(memory?.title, '');
    });

    test('a photo uploaded to the server is kept, by its name', () {
      final memory = Memory.tryParse({
        'date': '2025-02-14',
        'caption': 'Hi',
        'image': '0123456789abcdef.jpg',
      });
      expect(memory?.image, '0123456789abcdef.jpg');
      expect(memory?.hasServerPhoto, isTrue);
    });

    test('a bundled photo is not a server photo', () {
      final memory = Memory.tryParse({
        'date': '2025-02-14',
        'caption': 'Hi',
        'image': 'assets/memories/walk.jpg',
      });
      expect(memory?.hasServerPhoto, isFalse);
    });

    test('only names the server gives are accepted as server photos', () {
      expect(Memory.isServerPhoto('0123456789abcdef.png'), isTrue);
      expect(Memory.isServerPhoto('0123456789abcdef.webp'), isTrue);
      expect(Memory.isServerPhoto('../0123456789abcdef.jpg'), isFalse);
      expect(Memory.isServerPhoto('0123456789abcdef.exe'), isFalse);
      expect(Memory.isServerPhoto('0123456789ABCDEF.jpg'), isFalse);
      expect(Memory.isServerPhoto('photo.jpg'), isFalse);
      expect(Memory.isServerPhoto(''), isFalse);
    });

    test('a photo name that is not the server\'s is dropped, the memory kept',
        () {
      final memory = Memory.tryParse({
        'date': '2025-02-14',
        'caption': 'Hi',
        'image': '../../secret.jpg',
      });
      expect(memory?.caption, 'Hi');
      expect(memory?.image, isNull);
    });
  });
}
