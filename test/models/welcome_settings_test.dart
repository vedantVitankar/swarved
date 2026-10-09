import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/note_line.dart';
import 'package:swarved/models/welcome_settings.dart';

void main() {
  group('WelcomeSettings.parse', () {
    test('reads the line and the signature', () {
      final settings = WelcomeSettings.parse(
        {'line': 'Come as you are.', 'signature': 'Yours, Ved'},
      );

      expect(settings.line, 'Come as you are.');
      expect(settings.signature, 'Yours, Ved');
    });

    test('a bare string is the line', () {
      final settings = WelcomeSettings.parse('  Hello, you.  ');

      expect(settings.line, 'Hello, you.');
      expect(settings.signature, isNull);
    });

    test('blank or wrongly typed parts fall back to the default', () {
      final settings = WelcomeSettings.parse({'line': '   ', 'signature': 7});

      expect(settings.line, isNull);
      expect(settings.signature, isNull);
    });

    test('a missing or wrongly shaped value is all defaults', () {
      for (final json in [null, 42, <Object?>[], true]) {
        final settings = WelcomeSettings.parse(json);
        expect(settings.line, isNull);
        expect(settings.signature, isNull);
        expect(settings.story, isEmpty);
        expect(settings.notes, isEmpty);
      }
    });

    test('reads the story as a list of paragraphs', () {
      final settings = WelcomeSettings.parse({
        'story': ['  First.  ', 'Second.'],
      });

      expect(settings.story, ['First.', 'Second.']);
    });

    test('a single string is a story of one paragraph', () {
      final settings = WelcomeSettings.parse({'story': 'Just this.'});

      expect(settings.story, ['Just this.']);
    });

    test('blank or wrongly typed paragraphs are dropped, the rest kept', () {
      final settings = WelcomeSettings.parse({
        'story': ['Kept.', '   ', 7, null, 'Also kept.'],
      });

      expect(settings.story, ['Kept.', 'Also kept.']);
    });

    test('a story that is not text or a list is empty', () {
      for (final story in [42, true, <String, Object?>{}]) {
        expect(WelcomeSettings.parse({'story': story}).story, isEmpty);
      }
    });

    test('reads notes as plain strings or as label and note', () {
      final settings = WelcomeSettings.parse({
        'notes': [
          'Plain.',
          {'label': 'Gold', 'note': 'With a label.'},
        ],
      });

      expect(settings.notes, [
        const NoteLine(note: 'Plain.'),
        const NoteLine(label: 'Gold', note: 'With a label.'),
      ]);
    });

    test('one bad note does not spoil the others', () {
      final settings = WelcomeSettings.parse({
        'notes': [
          'Fine.',
          '',
          5,
          {'label': 'No words'},
          'Also fine.'
        ],
      });

      expect(settings.notes.map((note) => note.note), ['Fine.', 'Also fine.']);
    });

    test('notes that are not a list are empty', () {
      expect(WelcomeSettings.parse({'notes': 'nope'}).notes, isEmpty);
    });
  });
}
