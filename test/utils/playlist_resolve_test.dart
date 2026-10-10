import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/playlist.dart';
import 'package:swarved/models/playlist_item.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/utils/playlist_resolve.dart';

final _t0 = DateTime.utc(2026, 10, 11, 9);

Track _local(String title, {String path = '/music/a.mp3', int seconds = 200}) {
  return Track(
    filePath: path,
    title: title,
    artist: 'Artist',
    album: '',
    duration: Duration(seconds: seconds),
    folder: 'music',
  );
}

Track _youtube(String id) {
  return Track.youtube(
    videoId: id,
    title: 'Online $id',
    artist: 'Chan',
    duration: const Duration(seconds: 120),
    artworkUrl: 'https://x/$id.jpg',
  );
}

Playlist _playlistOf(List<Track> tracks) {
  return Playlist(
    id: 'pl_1',
    name: 'Mixed',
    kind: PlaylistKind.user,
    items: [
      for (final track in tracks) PlaylistItem.fromTrack(track, addedAt: _t0),
    ],
    createdAt: _t0,
    updatedAt: _t0,
  );
}

void main() {
  group('resolvePlaylist', () {
    test('a YouTube line plays from what it was saved with', () {
      final playlist = _playlistOf([_youtube('abc')]);

      final line = resolvePlaylist(playlist, const []).single;

      expect(line.isAvailable, isTrue);
      expect(line.track!.id, 'yt:abc');
      expect(line.track!.title, 'Online abc');
      expect(line.track!.artworkUrl, 'https://x/abc.jpg');
    });

    test('a local line is found in the library, wherever the file is', () {
      final onPhone = _local('Tum Hi Ho', path: '/phone/Tum Hi Ho.mp3');
      final onComputer = _local('Tum Hi Ho', path: r'D:\Songs\tum.mp3');
      final playlist = _playlistOf([onPhone]);

      final line = resolvePlaylist(playlist, [onComputer]).single;

      expect(line.isAvailable, isTrue);
      expect(line.track!.filePath, r'D:\Songs\tum.mp3');
    });

    test('a local song that is not here stays, but cannot be played', () {
      final playlist = _playlistOf([_local('Gone')]);

      final line = resolvePlaylist(playlist, [_local('Something else')]).single;

      expect(line.isAvailable, isFalse);
      expect(line.track, isNull);
      expect(line.item.title, 'Gone');
    });

    test('keeps the playlist order, mixed', () {
      final a = _local('A');
      final b = _youtube('bbb');
      final c = _local('C');
      final playlist = _playlistOf([c, b, a]);

      final lines = resolvePlaylist(playlist, [a, c]);

      expect([for (final l in lines) l.track?.title], ['C', 'Online bbb', 'A']);
    });

    test('the first of two copies in the library wins', () {
      final first = _local('Twin', path: '/one/twin.mp3');
      final second = _local('Twin', path: '/two/twin.mp3');
      final playlist = _playlistOf([first]);

      final line = resolvePlaylist(playlist, [first, second]).single;

      expect(line.track!.filePath, '/one/twin.mp3');
    });

    test('a YouTube line with nothing but its id still plays', () {
      final playlist = Playlist(
        id: 'pl_1',
        name: 'Odd',
        kind: PlaylistKind.user,
        items: [
          PlaylistItem(
            key: 'yt:x',
            title: 'ok',
            artist: '',
            duration: Duration.zero,
            addedAt: _t0,
          ),
        ],
        createdAt: _t0,
        updatedAt: _t0,
      );

      final line = resolvePlaylist(playlist, const []).single;

      expect(line.isAvailable, isTrue);
      expect(line.track!.videoId, 'x');
    });
  });

  group('playableTracks', () {
    test('leaves out the lines that are not here, and keeps the order', () {
      final a = _local('A');
      final playlist = _playlistOf([_youtube('one'), _local('Gone'), a]);

      final tracks = playableTracks(resolvePlaylist(playlist, [a]));

      expect([for (final t in tracks) t.id], ['yt:one', a.id]);
    });

    test('is empty when nothing can be played', () {
      final playlist = _playlistOf([_local('Gone')]);

      expect(playableTracks(resolvePlaylist(playlist, const [])), isEmpty);
    });
  });
}
