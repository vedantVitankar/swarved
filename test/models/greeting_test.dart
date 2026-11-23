import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/greeting.dart';

Map<String, Object?> _entry({
  Object? from = '05:00',
  Object? to = '12:00',
  Object? text = 'Good morning,\nSwarnima',
  Object? gold,
}) =>
    {'from': from, 'to': to, 'text': text, 'gold': gold};

DateTime _at(int hour, [int minute = 0]) => DateTime(2026, 11, 23, hour, minute);

void main() {
  group('Greeting.tryParse', () {
    test('reads the hours, the words and the gold line', () {
      final greeting = Greeting.tryParse(_entry(gold: ' Sleep well '))!;

      expect(greeting.from, 5 * 60);
      expect(greeting.to, 12 * 60);
      expect(greeting.text, 'Good morning,\nSwarnima');
      expect(greeting.gold, 'Sleep well');
    });

    test('an empty or missing gold line means the usual one', () {
      expect(Greeting.tryParse(_entry(gold: ''))!.gold, isNull);
      expect(Greeting.tryParse(_entry(gold: '   '))!.gold, isNull);
      expect(Greeting.tryParse(_entry())!.gold, isNull);
      expect(Greeting.tryParse({'from': '05:00', 'to': '12:00', 'text': 'Hi'})!.gold,
          isNull);
    });

    test('anything unusable is null', () {
      expect(Greeting.tryParse(null), isNull);
      expect(Greeting.tryParse('Hi'), isNull);
      expect(Greeting.tryParse(_entry(text: '')), isNull);
      expect(Greeting.tryParse(_entry(text: '  ')), isNull);
      expect(Greeting.tryParse(_entry(text: 5)), isNull);
      expect(Greeting.tryParse(_entry(from: null)), isNull);
      expect(Greeting.tryParse(_entry(to: 'noon')), isNull);
      expect(Greeting.tryParse(_entry(from: '24:00')), isNull);
      expect(Greeting.tryParse(_entry(from: '12:60')), isNull);
      expect(Greeting.tryParse(_entry(from: '08:00', to: '08:00')), isNull);
    });

    test('a time without a leading zero is understood', () {
      expect(Greeting.tryParse(_entry(from: '5:30'))!.from, 5 * 60 + 30);
    });
  });

  group('Greeting.covers', () {
    final morning = Greeting.tryParse(_entry())!;
    final night = Greeting.tryParse(
        _entry(from: '22:00', to: '05:00', text: 'Still up,\nbaby?'))!;

    test('the start counts and the end does not', () {
      expect(morning.covers(_at(5)), isTrue);
      expect(morning.covers(_at(4, 59)), isFalse);
      expect(morning.covers(_at(11, 59)), isTrue);
      expect(morning.covers(_at(12)), isFalse);
    });

    test('hours that run past midnight cover both sides of it', () {
      expect(night.covers(_at(22)), isTrue);
      expect(night.covers(_at(23, 59)), isTrue);
      expect(night.covers(_at(0)), isTrue);
      expect(night.covers(_at(4, 59)), isTrue);
      expect(night.covers(_at(5)), isFalse);
      expect(night.covers(_at(21, 59)), isFalse);
    });
  });

  test('two greetings with the same words are equal', () {
    expect(Greeting.tryParse(_entry()), Greeting.tryParse(_entry()));
    expect(Greeting.tryParse(_entry(gold: 'x')),
        isNot(Greeting.tryParse(_entry())));
  });
}
