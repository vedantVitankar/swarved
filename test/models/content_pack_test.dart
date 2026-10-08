import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/content_pack.dart';
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
}
