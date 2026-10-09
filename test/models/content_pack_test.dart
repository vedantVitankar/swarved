import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/content_pack.dart';
import 'package:swarved/models/note_slot.dart';
import 'package:swarved/models/track.dart';

Track _track(String title) => Track(
      filePath: '/music/$title.mp3',
      title: title,
      artist: 'Artist',
      album: '',
      duration: const Duration(minutes: 3),
      folder: 'music',
    );

void main() {
  group('ContentPack.parse', () {
    test('reads notes and keeps the optional label', () {
      final pack = ContentPack.parse('''
        {"notes": [
          {"title": "Kesariya", "label": "For you", "note": "Our first."},
          {"id": "yt:abc", "note": "Remember this?"}
        ]}''');

      expect(pack.notes, hasLength(2));
      expect(pack.notes.first.label, 'For you');
      expect(pack.notes.last.id, 'yt:abc');
      expect(pack.notes.last.label, isNull);
    });

    test('skips entries without a note or without a song', () {
      final pack = ContentPack.parse('''
        {"notes": [
          {"title": "No note here"},
          {"note": "No song here"},
          "not even an object",
          {"title": "Good", "note": "Kept."}
        ]}''');

      expect(pack.notes, hasLength(1));
      expect(pack.notes.single.title, 'Good');
    });

    test('a missing notes list is an empty pack', () {
      expect(ContentPack.parse('{}').notes, isEmpty);
    });

    test('something that is not an object throws', () {
      expect(() => ContentPack.parse('[]'), throwsFormatException);
      expect(() => ContentPack.parse('nope'), throwsFormatException);
    });

    test('noteFor returns the first match, or null', () {
      final pack = ContentPack.parse('''
        {"notes": [
          {"title": "Kesariya", "note": "First."},
          {"title": "Kesariya", "note": "Second."}
        ]}''');

      expect(pack.noteFor(_track('Kesariya'))?.note, 'First.');
      expect(pack.noteFor(_track('Other')), isNull);
    });
  });

  group('ContentPack song of the day', () {
    test('is read next to the notes', () {
      final pack = ContentPack.parse('''
        {"songOfTheDay": {"title": "Kesariya", "note": "Today."},
         "notes": [{"title": "Kesariya", "note": "Ours."}]}''');

      expect(pack.songOfTheDay?.title, 'Kesariya');
      expect(pack.songOfTheDay?.note, 'Today.');
      expect(pack.notes, hasLength(1));
    });

    test('is null when the file has none', () {
      expect(ContentPack.parse('{}').songOfTheDay, isNull);
      expect(ContentPack.empty.songOfTheDay, isNull);
    });

    test('a bad one is ignored and the notes still load', () {
      final pack = ContentPack.parse('''
        {"songOfTheDay": {"note": "No song named"},
         "notes": [{"title": "Kesariya", "note": "Ours."}]}''');

      expect(pack.songOfTheDay, isNull);
      expect(pack.notes, hasLength(1));
    });
  });

  group('ContentPack slots', () {
    test('reads strings and objects for a slot', () {
      final pack = ContentPack.parse('''
        {"slots": {"homeNote": [
          "First.",
          {"label": "Hers", "note": "Second."}
        ]}}''');

      final lines = pack.linesFor(NoteSlot.homeNote);
      expect(lines, hasLength(2));
      expect(lines.first.note, 'First.');
      expect(lines.first.label, isNull);
      expect(lines.last.label, 'Hers');
    });

    test('skips bad entries and leaves other slots empty', () {
      final pack = ContentPack.parse('''
        {"slots": {"usNote": ["", 5, {"label": "x"}, "Kept."]}}''');

      expect(pack.linesFor(NoteSlot.usNote).map((l) => l.note), ['Kept.']);
      expect(pack.linesFor(NoteSlot.homeNote), isEmpty);
      expect(pack.slots.containsKey(NoteSlot.homeNote), isFalse);
    });

    test('a slot whose notes are all bad is absent', () {
      final pack = ContentPack.parse('{"slots": {"loading": ["", 3]}}');
      expect(pack.slots, isEmpty);
    });

    test('unknown slots and a wrongly shaped "slots" are ignored', () {
      expect(ContentPack.parse('{"slots": {"nowhere": ["x"]}}').slots, isEmpty);
      expect(ContentPack.parse('{"slots": ["x"]}').slots, isEmpty);
      expect(ContentPack.parse('{"slots": {"homeNote": "x"}}').slots, isEmpty);
    });

    test('every slot is read from the key of its own name', () {
      final entries =
          NoteSlot.values.map((slot) => '"${slot.name}": ["x"]').join(',');
      final pack = ContentPack.parse('{"slots": {$entries}}');

      expect(pack.slots.keys.toSet(), NoteSlot.values.toSet());
    });
  });

  group('ContentPack folder notes', () {
    test('finds a folder by name, ignoring case and punctuation', () {
      final pack = ContentPack.parse('''
        {"folderNotes": [
          {"folder": "Slow dances", "label": "L", "note": "For the nights."}
        ]}''');

      expect(pack.folderNoteFor('slow  dances!')?.note, 'For the nights.');
      expect(pack.folderNoteFor('Slow dances')?.label, 'L');
      expect(pack.folderNoteFor('Road trip'), isNull);
    });

    test('skips entries missing a folder or a note; the first one wins', () {
      final pack = ContentPack.parse('''
        {"folderNotes": [
          {"note": "No folder"},
          {"folder": "Mornings"},
          {"folder": "Mornings", "note": "First."},
          {"folder": "mornings", "note": "Second."},
          "nope"
        ]}''');

      expect(pack.folderNotes, hasLength(1));
      expect(pack.folderNoteFor('Mornings')?.note, 'First.');
    });
  });

  group('ContentPack welcome', () {
    test('is read from the file', () {
      final pack = ContentPack.parse(
          '{"welcome": {"line": "Hi.", "signature": "Ved"}}');

      expect(pack.welcome.line, 'Hi.');
      expect(pack.welcome.signature, 'Ved');
    });

    test('is all defaults when the file has none', () {
      final pack = ContentPack.parse('{}');

      expect(pack.welcome.line, isNull);
      expect(pack.welcome.signature, isNull);
    });
  });
}
