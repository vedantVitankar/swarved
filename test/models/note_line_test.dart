import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/note_line.dart';

void main() {
  group('NoteLine.tryParse', () {
    test('a bare string is a note with no label', () {
      final line = NoteLine.tryParse('  I miss you.  ');
      expect(line?.note, 'I miss you.');
      expect(line?.label, isNull);
    });

    test('an object can carry its own label', () {
      final line =
          NoteLine.tryParse({'label': ' Just us ', 'note': 'Hello, baby.'});
      expect(line?.label, 'Just us');
      expect(line?.note, 'Hello, baby.');
    });

    test('a blank label counts as none', () {
      expect(NoteLine.tryParse({'label': '  ', 'note': 'Hi'})?.label, isNull);
    });

    test('an empty note, or the wrong shape, is rejected', () {
      expect(NoteLine.tryParse(''), isNull);
      expect(NoteLine.tryParse('   '), isNull);
      expect(NoteLine.tryParse({'label': 'No note'}), isNull);
      expect(NoteLine.tryParse({'note': '  '}), isNull);
      expect(NoteLine.tryParse({'note': 5}), isNull);
      expect(NoteLine.tryParse(5), isNull);
      expect(NoteLine.tryParse(null), isNull);
      expect(NoteLine.tryParse(['a']), isNull);
    });

    test('two notes with the same words are equal', () {
      expect(const NoteLine(label: 'A', note: 'B'),
          const NoteLine(label: 'A', note: 'B'));
      expect(const NoteLine(note: 'B') == const NoteLine(label: 'A', note: 'B'),
          isFalse);
    });
  });
}
