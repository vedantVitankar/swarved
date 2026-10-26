import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/memory.dart';
import 'package:swarved/models/track.dart';

void main() {
  group('a memory in the right-hand section', () {
    Map<String, Object?> entry([Map<String, Object?> change = const {}]) => {
          'date': '2026-03-12',
          'caption': 'The evening you laughed.',
          ...change,
        };

    test('shows there unless he keeps it for memory lane', () {
      expect(Memory.tryParse(entry())!.inPanel, isTrue);
      expect(Memory.tryParse(entry({'hideFromPanel': true}))!.inPanel, isFalse);
      expect(Memory.tryParse(entry({'hideFromPanel': 'yes'}))!.inPanel, isTrue);
    });

    test('has no song unless he gave one', () {
      expect(Memory.tryParse(entry())!.song, isNull);
    });

    test('keeps a YouTube song with its words', () {
      final memory = Memory.tryParse(entry({
        'song': {'id': 'yt:dQw4w9WgXcQ', 'title': 'So Stunning', 'artist': 'Artemas'},
      }))!;
      expect(memory.song!.id, 'yt:dQw4w9WgXcQ');
      expect(memory.song!.title, 'So Stunning');
      expect(memory.song!.artist, 'Artemas');
    });

    test('a bad song is no song, and the memory stays', () {
      for (final bad in [
        {'title': ''},
        {'id': 'dQw4w9WgXcQ', 'title': 'x'},
        'So Stunning',
        7,
      ]) {
        final memory = Memory.tryParse(entry({'song': bad}));
        expect(memory, isNotNull);
        expect(memory!.song, isNull, reason: '$bad');
      }
    });
  });

  group('a letter\'s recording', () {
    Track track({String folder = Track.letterRecordingFolder}) => Track(
          filePath: '/media/aaaaaaaaaaaaaaaa.mp3',
          title: 'Open when you miss me',
          artist: 'From Ved, with love',
          album: '',
          duration: Duration.zero,
          folder: folder,
        );

    test('is told apart from a song by its folder', () {
      expect(track().isLetterRecording, isTrue);
      expect(track(folder: 'Music').isLetterRecording, isFalse);
    });

    test('a YouTube song is never one', () {
      final song = Track.youtube(
        videoId: 'dQw4w9WgXcQ',
        title: 'x',
        artist: 'y',
        duration: Duration.zero,
      );
      expect(song.isLetterRecording, isFalse);
    });
  });
}
