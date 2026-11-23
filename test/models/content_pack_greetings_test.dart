import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/content_pack.dart';

DateTime _at(int hour, [int minute = 0]) => DateTime(2026, 11, 23, hour, minute);

void main() {
  group('ContentPack greetings', () {
    test('none written means none, and the app uses its own', () {
      final pack = ContentPack.parse('{}');

      expect(pack.greetings, isEmpty);
      expect(pack.greetingFor(_at(8)), isNull);
    });

    test('a list that is not a list is ignored', () {
      expect(ContentPack.parse('{"greetings": "hi"}').greetings, isEmpty);
    });

    test('a bad entry is skipped and the others are kept in order', () {
      final pack = ContentPack.parse('''{"greetings": [
        {"from": "05:00", "to": "12:00", "text": "Morning", "gold": "Soft day"},
        {"from": "nope", "to": "12:00", "text": "Broken"},
        {"from": "12:00", "to": "17:00", "text": "Afternoon"}
      ]}''');

      expect(pack.greetings.map((g) => g.text).toList(), ['Morning', 'Afternoon']);
      expect(pack.greetings.first.gold, 'Soft day');
    });

    test('the greeting for an hour is the first that covers it', () {
      final pack = ContentPack.parse('''{"greetings": [
        {"from": "05:00", "to": "12:00", "text": "Morning"},
        {"from": "08:00", "to": "10:00", "text": "Overlap"},
        {"from": "22:00", "to": "05:00", "text": "Late"}
      ]}''');

      expect(pack.greetingFor(_at(9))!.text, 'Morning');
      expect(pack.greetingFor(_at(23))!.text, 'Late');
      expect(pack.greetingFor(_at(2))!.text, 'Late');
      expect(pack.greetingFor(_at(15)), isNull);
    });
  });
}
