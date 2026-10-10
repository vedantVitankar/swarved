import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/content/words.dart';
import 'package:swarved/models/tutorial_settings.dart';
import 'package:swarved/services/tutorial_song_service.dart';

Uint8List _bytes(List<int> values) => Uint8List.fromList(values);

void main() {
  late Directory cache;

  setUp(() {
    cache = Directory.systemTemp.createTempSync('tutorial_song_test');
    addTearDown(() => cache.deleteSync(recursive: true));
  });

  TutorialSongService service({
    Future<Uint8List> Function(String asset)? loadAsset,
    SongTags? Function(String path)? readTags,
  }) {
    return TutorialSongService(
      loadAsset: loadAsset ?? (_) async => _bytes([1, 2, 3, 4, 5]),
      readTags: readTags ?? (_) => null,
      cacheDirectory: () async => cache,
    );
  }

  group('TutorialSongService.prepare', () {
    test('copies the bundled song into the cache and builds a track',
        () async {
      String? readFrom;
      final song = await service(
        readTags: (path) {
          readFrom = path;
          return const SongTags(
            title: 'Asal - How Bad',
            artist: 'Asal',
            album: 'Singles',
            duration: Duration(minutes: 3, seconds: 20),
            cover: [9, 9],
          );
        },
      ).prepare(const TutorialSettings(asset: 'assets/welcome/song.mp3'));

      final track = song!.track;
      expect(File(track.filePath).existsSync(), isTrue);
      expect(File(track.filePath).readAsBytesSync(), [1, 2, 3, 4, 5]);
      expect(track.filePath.endsWith('song.mp3'), isTrue);
      expect(readFrom, track.filePath);
      expect(track.title, 'Asal - How Bad');
      expect(track.artist, 'Asal');
      expect(track.album, 'Singles');
      expect(track.duration, const Duration(minutes: 3, seconds: 20));
      expect(track.artworkBytes, [9, 9]);
      expect(track.isLocal, isTrue);
      // "Playing from ..." on Now Playing needs a folder to name.
      expect(track.folder, Words.tutorialSongFolder);
    });

    test('his title and artist win over the tags, and the words carry over',
        () async {
      final song = await service(
        readTags: (_) => const SongTags(title: 'Tag title', artist: 'Tag'),
      ).prepare(const TutorialSettings(
        title: 'How Bad',
        artist: 'Asal',
        label: 'For you',
        note: 'Our first song here.',
      ));

      expect(song!.track.title, 'How Bad');
      expect(song.track.artist, 'Asal');
      expect(song.label, 'For you');
      expect(song.note, 'Our first song here.');
    });

    test('with no tags it uses the file name and no artist', () async {
      final song = await service().prepare(
        const TutorialSettings(asset: 'assets/welcome/how_bad.mp3'),
      );

      expect(song!.track.title, 'how_bad');
      expect(song.track.artist, '');
      expect(song.track.duration, Duration.zero);
      expect(song.track.artworkBytes, isNull);
    });

    test('blank tags count as no tags', () async {
      final song = await service(
        readTags: (_) => const SongTags(title: '  ', artist: ''),
      ).prepare(const TutorialSettings(asset: 'assets/welcome/song.mp3'));

      expect(song!.track.title, 'song');
      expect(song.track.artist, '');
    });

    test('a song that is not in the app gives no song, not an error',
        () async {
      final song = await service(
        loadAsset: (_) async => throw Exception('Unable to load asset'),
      ).prepare(const TutorialSettings());

      expect(song, isNull);
    });

    test('a cache that cannot be written gives no song, not an error',
        () async {
      final broken = TutorialSongService(
        loadAsset: (_) async => _bytes([1, 2, 3]),
        readTags: (_) => null,
        cacheDirectory: () async => throw const FileSystemException('full'),
      );

      expect(await broken.prepare(const TutorialSettings()), isNull);
    });

    test('a song already copied is not copied again', () async {
      final first = await service().prepare(const TutorialSettings());
      // Same length, different contents: if it were copied again the
      // marker would be gone.
      File(first!.track.filePath).writeAsBytesSync([7, 7, 7, 7, 7]);

      final second = await service().prepare(const TutorialSettings());

      expect(File(second!.track.filePath).readAsBytesSync(), [7, 7, 7, 7, 7]);
      expect(second.track.filePath, first.track.filePath);
    });

    test('a different song under the same name replaces the old one',
        () async {
      await service().prepare(const TutorialSettings());

      final swapped = await service(
        loadAsset: (_) async => _bytes([8, 8, 8]),
      ).prepare(const TutorialSettings());

      expect(File(swapped!.track.filePath).readAsBytesSync(), [8, 8, 8]);
    });
  });
}
