import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/note_slot.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/services/content_service.dart';

final _track = Track(
  filePath: '/music/Kesariya.mp3',
  title: 'Kesariya',
  artist: 'Artist',
  album: '',
  duration: const Duration(minutes: 3),
  folder: 'music',
);

final _other = Track(
  filePath: '/music/Other.mp3',
  title: 'Other',
  artist: 'Artist',
  album: '',
  duration: const Duration(minutes: 3),
  folder: 'music',
);

void main() {
  group('ContentService', () {
    test('loads notes and tells listeners', () async {
      final service = ContentService(
        loader: () async => '{"notes":[{"title":"Kesariya","note":"Ours."}]}',
      );
      var told = 0;
      service.addListener(() => told++);

      await service.load();

      expect(service.noteFor(_track)?.note, 'Ours.');
      expect(told, 1);
    });

    test('a broken file leaves it empty and does not throw', () async {
      final service = ContentService(loader: () async => 'not json');
      await service.load();
      expect(service.noteFor(_track), isNull);
    });

    test('a loader that fails leaves it empty and does not throw', () async {
      final service = ContentService(loader: () async => throw Exception('no'));
      await service.load();
      expect(service.pack.notes, isEmpty);
    });

    test('exposes the song of the day, and none before it loads', () async {
      final service = ContentService(
        loader: () async => '{"songOfTheDay":{"title":"Kesariya"}}',
      );
      expect(service.songOfTheDay, isNull);

      await service.load();

      expect(service.songOfTheDay?.title, 'Kesariya');
    });

    test('lineFor walks through a slot by seed, and is null when empty',
        () async {
      final service = ContentService(
        loader: () async => '{"slots":{"homeNote":["A","B","C"]}}',
      );
      await service.load();

      expect(service.lineFor(NoteSlot.homeNote, seed: 0)?.note, 'A');
      expect(service.lineFor(NoteSlot.homeNote, seed: 4)?.note, 'B');
      expect(service.lineFor(NoteSlot.usNote, seed: 0), isNull);
    });

    test('lineFor without a seed gives one of the notes', () async {
      final service = ContentService(
        loader: () async => '{"slots":{"homeNote":["A","B"]}}',
      );
      await service.load();

      expect(['A', 'B'], contains(service.lineFor(NoteSlot.homeNote)?.note));
    });

    test('noteLineFor prefers the song\'s own note', () async {
      final service = ContentService(
        loader: () async => '''
          {"notes":[{"title":"Kesariya","label":"Ours","note":"Our song."}],
           "slots":{"playingNote":["General."]}}''',
      );
      await service.load();

      final line = service.noteLineFor(_track);
      expect(line?.note, 'Our song.');
      expect(line?.label, 'Ours');
    });

    test('noteLineFor falls back to a playing note, the same one each time',
        () async {
      final service = ContentService(
        loader: () async =>
            '{"slots":{"playingNote":["One.","Two.","Three."]}}',
      );
      await service.load();

      final first = service.noteLineFor(_other);
      expect(first, isNotNull);
      expect(service.noteLineFor(_other), first);
    });

    test('noteLineFor is null with no own note and no playing notes', () async {
      final service = ContentService(loader: () async => '{}');
      await service.load();
      expect(service.noteLineFor(_other), isNull);
    });

    test('folderNoteFor finds a folder note', () async {
      final service = ContentService(
        loader: () async =>
            '{"folderNotes":[{"folder":"Mornings","note":"Wake up."}]}',
      );
      await service.load();

      expect(service.folderNoteFor('mornings')?.note, 'Wake up.');
      expect(service.folderNoteFor('Late night'), isNull);
    });
  });
}
