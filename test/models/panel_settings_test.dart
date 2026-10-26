import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/panel_settings.dart';

void main() {
  group('PanelSettings.parse', () {
    test('anything that is not a map is the plain default', () {
      for (final bad in [null, 'panel', 7, <Object>[]]) {
        final settings = PanelSettings.parse(bad);
        expect(settings.pinned, '');
        expect(settings.hidden, isEmpty);
        expect(settings.order, isEmpty);
      }
    });

    test('with nothing chosen every part shows, in the usual order', () {
      expect(PanelSettings.none.shown, [
        PanelBlock.countdown,
        PanelBlock.onThisDay,
        PanelBlock.letters,
        PanelBlock.photoNotes,
      ]);
    });

    test('the hide switches take parts out, and only when they are true', () {
      final settings = PanelSettings.parse({
        'hideCountdown': true,
        'hideLetters': true,
        'hideOnThisDay': false,
        'hidePhotoNotes': 'yes',
      });
      expect(settings.hidden, {PanelBlock.countdown, PanelBlock.letters});
      expect(settings.shown, [PanelBlock.onThisDay, PanelBlock.photoNotes]);
    });

    test('his order is followed, and parts he left out come last', () {
      final settings = PanelSettings.parse({
        'order': ['photoNotes', 'letters'],
      });
      expect(settings.shown, [
        PanelBlock.photoNotes,
        PanelBlock.letters,
        PanelBlock.countdown,
        PanelBlock.onThisDay,
      ]);
    });

    test('an order with unknown, repeated or odd entries still works', () {
      final settings = PanelSettings.parse({
        'order': ['letters', 'nope', 'letters', 5, null, 'countdown'],
      });
      expect(settings.order, [PanelBlock.letters, PanelBlock.countdown]);
      expect(settings.shown.length, 4);
      expect(settings.shown.first, PanelBlock.letters);
    });

    test('an order that is not a list is ignored', () {
      expect(PanelSettings.parse({'order': 'letters'}).order, isEmpty);
    });

    test('a hidden part stays out wherever it is in the order', () {
      final settings = PanelSettings.parse({
        'order': ['letters', 'countdown'],
        'hideLetters': true,
      });
      expect(settings.shown.first, PanelBlock.countdown);
      expect(settings.shown, isNot(contains(PanelBlock.letters)));
    });

    test('his own titles are kept, trimmed', () {
      final settings = PanelSettings.parse({
        'lettersTitle': '  Open when…  ',
        'photoNotesTitle': 'Us',
      });
      expect(settings.lettersTitle, 'Open when…');
      expect(settings.photoNotesTitle, 'Us');
    });

    test('only an uploaded photo can be pinned', () {
      expect(
        PanelSettings.parse({'pinnedPhoto': 'aaaaaaaaaaaaaaaa.jpg'}).pinnedPhoto,
        'aaaaaaaaaaaaaaaa.jpg',
      );
      for (final bad in [
        'assets/x.jpg',
        'photo.jpg',
        'aaaaaaaaaaaaaaaa.mp3',
        '../aaaaaaaaaaaaaaaa.jpg',
      ]) {
        expect(PanelSettings.parse({'pinnedPhoto': bad}).pinnedPhoto, isNull,
            reason: bad);
      }
    });
  });

  group('the pinned note', () {
    PanelSettings pinned({String? until}) => PanelSettings.parse({
          'pinned': ' Happy birthday ',
          'pinnedLabel': 'Today',
          'pinnedPhoto': 'aaaaaaaaaaaaaaaa.jpg',
          if (until != null) 'pinnedUntil': until,
        });

    test('there is none without words', () {
      expect(PanelSettings.parse({'pinnedLabel': 'x'}).pinnedOn(DateTime(2026)),
          isNull);
    });

    test('it carries its words, heading and photo', () {
      final note = pinned().pinnedOn(DateTime(2026, 5, 1))!;
      expect(note.text, 'Happy birthday');
      expect(note.label, 'Today');
      expect(note.photo, 'aaaaaaaaaaaaaaaa.jpg');
    });

    test('with no end day it always shows', () {
      expect(pinned().pinnedOn(DateTime(2040, 1, 1)), isNotNull);
    });

    test('it shows through its last day and goes after', () {
      final settings = pinned(until: '2026-12-25');
      expect(settings.pinnedOn(DateTime(2026, 12, 24, 23, 59)), isNotNull);
      expect(settings.pinnedOn(DateTime(2026, 12, 25, 23, 59)), isNotNull);
      expect(settings.pinnedOn(DateTime(2026, 12, 26)), isNull);
    });

    test('a made-up end day is ignored, so the note stays', () {
      expect(pinned(until: '2026-02-30').pinnedUntil, isNull);
      expect(pinned(until: 'soon').pinnedOn(DateTime(2030)), isNotNull);
    });
  });
}
