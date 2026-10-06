import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/models/track_source.dart';

void main() {
  group('Track', () {
    test('a local track keeps its file path as its id', () {
      final track = Track(
        filePath: '/music/a.mp3',
        title: 'A',
        artist: 'Artist',
        album: 'Album',
        duration: const Duration(minutes: 3),
        folder: 'music',
      );

      expect(track.source, TrackSource.local);
      expect(track.isLocal, true);
      expect(track.id, '/music/a.mp3');
      expect(track.videoId, isNull);
    });

    test('a YouTube track is identified by its video id, not a path', () {
      final track = Track.youtube(
        videoId: 'abc123',
        title: 'Song',
        artist: 'Channel',
        duration: const Duration(minutes: 4),
        artworkUrl: 'https://i.ytimg.com/vi/abc123/hqdefault.jpg',
      );

      expect(track.source, TrackSource.youtube);
      expect(track.isLocal, false);
      expect(track.id, 'yt:abc123');
      expect(track.filePath, isEmpty);
      expect(track.artworkUrl, isNotNull);
    });

    test('a YouTube track without a video id is rejected', () {
      expect(
        () => Track(
          filePath: '',
          title: 'X',
          artist: 'Y',
          album: '',
          duration: Duration.zero,
          folder: '',
          source: TrackSource.youtube,
        ),
        throwsAssertionError,
      );
    });
  });
}
