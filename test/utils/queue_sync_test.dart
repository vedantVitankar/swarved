import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/utils/queue_sync.dart';
import 'package:swarved/utils/track_key.dart';

Track _song(String id) => Track.youtube(
  videoId: id,
  title: 'Song $id',
  artist: 'Artist',
  duration: const Duration(seconds: 100),
);

Track _local(String title) => Track(
  filePath: '/music/$title.mp3',
  title: title,
  artist: 'Artist',
  album: '',
  duration: const Duration(seconds: 200),
  folder: 'music',
);

List<String> _ids(QueueSync sync) => [for (final t in sync.queue) t.id];

Set<String> _keys(List<Track> tracks) => {
  for (final t in tracks) t.playlistKey,
};

QueueSync _sync(
  List<Track> old,
  List<Track> wanted, {
  int playing = 0,
  Set<String>? inPlaylist,
}) {
  return QueueSync.compute(
    oldQueue: old,
    playing: playing,
    wanted: wanted,
    inPlaylist: inPlaylist ?? _keys(wanted),
  );
}

void main() {
  final a = _song('a');
  final b = _song('b');
  final c = _song('c');
  final d = _song('d');

  group('nothing changed', () {
    test('the same songs in the same order are not a change', () {
      final sync = _sync([a, b, c], [_song('a'), _song('b'), _song('c')]);

      expect(sync.changed, isFalse);
      expect(sync.added, isEmpty);
      expect(sync.oldToNew, [0, 1, 2]);
    });

    test('keeps the objects the player already holds', () {
      final sync = _sync([a, b], [_song('a'), _song('b')]);

      expect(identical(sync.queue[0], a), isTrue);
      expect(identical(sync.queue[1], b), isTrue);
    });
  });

  group('a song is added', () {
    test('it joins at the place the playlist has it', () {
      final sync = _sync([a, b], [a, b, c]);

      expect(sync.changed, isTrue);
      expect(_ids(sync), ['yt:a', 'yt:b', 'yt:c']);
      expect(sync.added, [2]);
      expect(sync.oldToNew, [0, 1]);
    });

    test('the new song is the one from the playlist', () {
      final sync = _sync([a], [a, c]);

      expect(identical(sync.queue[1], c), isTrue);
    });
  });

  group('a song is taken out', () {
    test('it leaves the queue and the others move up', () {
      final sync = _sync([a, b, c], [a, c], playing: 0);

      expect(_ids(sync), ['yt:a', 'yt:c']);
      expect(sync.oldToNew, [0, null, 1]);
    });

    test('the song playing finishes even when it is taken out', () {
      final sync = _sync([a, b, c], [a, c], playing: 1);

      expect(_ids(sync), ['yt:a', 'yt:b', 'yt:c']);
      expect(sync.oldToNew, [0, 1, 2]);
      expect(sync.changed, isFalse);
    });

    test('a playing song that was taken out keeps its place in line', () {
      final sync = _sync([a, b, c], [c, d], playing: 1);

      // b stays just before c, the song that followed it.
      expect(_ids(sync), ['yt:b', 'yt:c', 'yt:d']);
      expect(sync.oldToNew, [null, 0, 1]);
      expect(sync.added, [2]);
    });

    test('an emptied playlist leaves only the song playing', () {
      final sync = _sync([a, b, c], [], playing: 2);

      expect(_ids(sync), ['yt:c']);
      expect(sync.oldToNew, [null, null, 0]);
    });
  });

  group('a song is moved', () {
    test('the queue follows the new order', () {
      final sync = _sync([a, b, c], [c, a, b], playing: 1);

      expect(_ids(sync), ['yt:c', 'yt:a', 'yt:b']);
      expect(sync.oldToNew, [1, 2, 0]);
      expect(sync.changed, isTrue);
      expect(sync.added, isEmpty);
    });
  });

  group('local songs that are not on this device', () {
    test('stay in the queue while the playlist still has them', () {
      final x = _local('x');
      final y = _local('y');
      // The playlist has y, but the library cannot supply it right now.
      final sync = _sync(
        [x, y, a],
        [x, a],
        playing: 0,
        inPlaylist: {x.playlistKey, y.playlistKey, a.playlistKey},
      );

      expect(sync.changed, isFalse);
      expect(_ids(sync), [x.id, y.id, 'yt:a']);
    });

    test('go once the playlist no longer has them', () {
      final x = _local('x');
      final y = _local('y');
      final sync = _sync([x, y, a], [x, a], playing: 0);

      expect(_ids(sync), [x.id, 'yt:a']);
      expect(sync.oldToNew, [0, null, 1]);
    });
  });

  test('a song twice in the queue is matched once each', () {
    final sync = _sync([a, a, b], [a, b], playing: 2);

    expect(_ids(sync), ['yt:a', 'yt:b']);
    expect(sync.oldToNew, [0, null, 1]);
  });

  test('every old position that stays is in the new queue exactly once', () {
    final sync = _sync([a, b, c, d], [d, _song('e'), b], playing: 2);

    final stayed = [
      for (final n in sync.oldToNew)
        if (n != null) n,
    ];
    expect(stayed.toSet().length, stayed.length);
    expect(stayed.length + sync.added.length, sync.queue.length);
  });
}
