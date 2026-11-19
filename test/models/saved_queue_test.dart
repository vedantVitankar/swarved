import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/saved_queue.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/utils/queue_order.dart';

Track _yt(String id, {int seconds = 200, String? art}) => Track.youtube(
      videoId: id,
      title: 'Song $id',
      artist: 'Artist $id',
      duration: Duration(seconds: seconds),
      artworkUrl: art,
    );

Track _local(String name, {int seconds = 180}) => Track(
      filePath: '/music/$name.mp3',
      title: name,
      artist: 'Local artist',
      album: 'An album',
      duration: Duration(seconds: seconds),
      folder: 'music',
      artworkBytes: const [1, 2, 3], // never saved
    );

SavedQueue _saved({
  List<Track>? tracks,
  int index = 1,
  int positionSeconds = 42,
  Map<String, Object?>? order,
  String? sourceName = 'Late night',
  String? playlistId = 'pl-1',
}) =>
    SavedQueue(
      tracks:
          tracks ?? [_yt('aaaaaaaaaaa'), _local('Blue'), _yt('ccccccccccc')],
      index: index,
      position: Duration(seconds: positionSeconds),
      order: order,
      sourceName: sourceName,
      sourcePlaylistId: playlistId,
      savedAt: DateTime.utc(2026, 11, 2, 9, 30),
    );

/// What the file would hold: written as text and read back.
SavedQueue? _roundTrip(SavedQueue saved) =>
    SavedQueue.tryParse(jsonDecode(jsonEncode(saved.toJson())));

void main() {
  group('SavedQueue round trip', () {
    test('keeps the songs, where she was, how far in, and the playlist', () {
      final back = _roundTrip(_saved())!;
      expect(back.tracks.length, 3);
      expect(back.index, 1);
      expect(back.current.title, 'Blue');
      expect(back.position, const Duration(seconds: 42));
      expect(back.sourceName, 'Late night');
      expect(back.sourcePlaylistId, 'pl-1');
      expect(back.savedAt, DateTime.utc(2026, 11, 2, 9, 30));
    });

    test('a YouTube song keeps its id, names, length and picture', () {
      final back = _roundTrip(_saved(
        tracks: [
          _yt('Wzx3JwxUpVA', seconds: 139, art: 'https://i.ytimg.com/a.jpg')
        ],
        index: 0,
      ))!;
      final song = back.tracks.single;
      expect(song.isLocal, isFalse);
      expect(song.videoId, 'Wzx3JwxUpVA');
      expect(song.id, 'yt:Wzx3JwxUpVA');
      expect(song.title, 'Song Wzx3JwxUpVA');
      expect(song.artist, 'Artist Wzx3JwxUpVA');
      expect(song.duration, const Duration(seconds: 139));
      expect(song.artworkUrl, 'https://i.ytimg.com/a.jpg');
    });

    test('a local song keeps its file and details, but not its picture bytes',
        () {
      final song = _roundTrip(_saved())!.tracks[1];
      expect(song.isLocal, isTrue);
      expect(song.filePath, '/music/Blue.mp3');
      expect(song.id, '/music/Blue.mp3');
      expect(song.album, 'An album');
      expect(song.folder, 'music');
      expect(song.duration, const Duration(seconds: 180));
      expect(song.artworkBytes, isNull);
    });

    test('the play order survives, so a shuffled queue keeps its sequence', () {
      final order = QueueOrder()
        ..start(length: 3, startIndex: 1)
        ..setShuffle(true);
      final back = _roundTrip(_saved(order: order.toJson()))!;
      final restored = QueueOrder();
      expect(restored.restore(back.order, length: 3), isTrue);
      expect(restored.currentIndex, order.currentIndex);
      expect(restored.shuffle, isTrue);
    });

    test('no playlist is fine: a folder or a search has no name', () {
      final back = _roundTrip(_saved(sourceName: null, playlistId: null))!;
      expect(back.sourceName, isNull);
      expect(back.sourcePlaylistId, isNull);
    });

    test('a playlist name without an id (an older save) still reads', () {
      final back = _roundTrip(_saved(playlistId: null))!;
      expect(back.sourceName, 'Late night');
      expect(back.sourcePlaylistId, isNull);
    });

    test('saved at the very end of a song, it starts that song again', () {
      final back = _roundTrip(_saved(
        tracks: [_yt('aaaaaaaaaaa', seconds: 200)],
        index: 0,
        positionSeconds: 200,
      ))!;
      expect(back.position, Duration.zero);
    });

    test('a song of unknown length keeps whatever position was saved', () {
      final back = _roundTrip(_saved(
        tracks: [_yt('aaaaaaaaaaa', seconds: 0)],
        index: 0,
        positionSeconds: 95,
      ))!;
      expect(back.position, const Duration(seconds: 95));
    });
  });

  group('SavedQueue refuses what it cannot trust', () {
    Map<String, Object?> good() =>
        jsonDecode(jsonEncode(_saved().toJson())) as Map<String, Object?>;

    test('nothing, and things that are not a saved queue, are "nothing saved"',
        () {
      for (final raw in <Object?>[
        null,
        'text',
        5,
        [],
        {},
        {'version': 1}
      ]) {
        expect(SavedQueue.tryParse(raw), isNull, reason: '$raw');
      }
    });

    test('a file from a newer app is ignored, not half understood', () {
      expect(SavedQueue.tryParse({...good(), 'version': 2}), isNull);
      expect(SavedQueue.tryParse({...good(), 'version': 0}), isNull);
    });

    test('a position outside the queue, or a bad time, is refused', () {
      for (final bad in <Map<String, Object?>>[
        {'index': 3},
        {'index': -1},
        {'index': '1'},
        {'positionMs': -5},
        {'positionMs': 'soon'},
      ]) {
        expect(SavedQueue.tryParse({...good(), ...bad}), isNull,
            reason: '$bad');
      }
    });

    test('an empty queue, or one too big to be hers, is refused', () {
      expect(SavedQueue.tryParse({...good(), 'tracks': []}), isNull);
      final huge = [
        for (var i = 0; i < SavedQueue.maxTracks + 1; i++)
          {
            'kind': 'youtube',
            'videoId': 'abcdefghijk',
            'title': 't',
            'artist': 'a',
            'ms': 1000
          },
      ];
      expect(SavedQueue.tryParse({...good(), 'tracks': huge}), isNull);
    });

    test(
        'one damaged song refuses the whole queue, so the sequence is never wrong',
        () {
      final tracks = List<Object?>.from(good()['tracks'] as List);
      for (final bad in <Object?>[
        null,
        'x',
        {'kind': 'youtube'},
        {
          'kind': 'youtube',
          'videoId': '',
          'title': 't',
          'artist': 'a',
          'ms': 1
        },
        {'kind': 'local', 'path': '', 'title': 't', 'artist': 'a', 'ms': 1},
        {'kind': 'radio', 'title': 't', 'artist': 'a', 'ms': 1},
        {
          'kind': 'youtube',
          'videoId': 'abcdefghijk',
          'title': 5,
          'artist': 'a',
          'ms': 1
        },
        {
          'kind': 'youtube',
          'videoId': 'abcdefghijk',
          'title': 't',
          'artist': 'a',
          'ms': -1
        },
      ]) {
        final withBad = [...tracks]..[0] = bad;
        expect(SavedQueue.tryParse({...good(), 'tracks': withBad}), isNull,
            reason: '$bad');
      }
    });

    test('a damaged play order is carried but caught by QueueOrder, not here',
        () {
      final back = SavedQueue.tryParse({...good(), 'order': 'garbage'})!;
      expect(back.order, isNull);
    });
  });

  group('SavedQueue when songs are gone', () {
    bool Function(Track) without(String title) => (t) => t.title != title;

    test('nothing gone: the very same queue, order and all', () {
      final saved = _saved(order: const {
        'order': [0, 1, 2]
      });
      expect(identical(saved.keeping((_) => true), saved), isTrue);
    });

    test('a song before the current one goes: the current song stays current',
        () {
      final kept = _saved(index: 2, order: const {
        'order': [0, 1, 2]
      }).keeping(without('Blue'))!;
      expect(kept.tracks.map((t) => t.title).toList(),
          ['Song aaaaaaaaaaa', 'Song ccccccccccc']);
      expect(kept.index, 1);
      expect(kept.current.title, 'Song ccccccccccc');
      expect(kept.position, const Duration(seconds: 42));
      expect(kept.order, isNull, reason: 'the old order no longer fits');
      expect(kept.sourcePlaylistId, 'pl-1');
    });

    test(
        'the current song itself goes: the next one takes over, from its start',
        () {
      final kept = _saved(index: 1).keeping(without('Blue'))!;
      expect(kept.current.title, 'Song ccccccccccc');
      expect(kept.index, 1);
      expect(kept.position, Duration.zero);
    });

    test('the current song is the last and goes: the one before takes over',
        () {
      final kept = _saved(index: 2).keeping(without('Song ccccccccccc'))!;
      expect(kept.current.title, 'Blue');
      expect(kept.index, 1);
      expect(kept.position, Duration.zero);
    });

    test('every song gone: nothing to restore', () {
      expect(_saved().keeping((_) => false), isNull);
    });
  });

  group('SavedQueue putting artwork back', () {
    test('mapTracks swaps songs but moves nothing else', () {
      final saved = _saved(order: const {
        'order': [2, 0, 1]
      });
      final swapped = saved.mapTracks((t) => t.isLocal ? _local('Blue') : t);
      expect(swapped.tracks[1].artworkBytes, [1, 2, 3]);
      expect(swapped.index, saved.index);
      expect(swapped.position, saved.position);
      expect(swapped.order, saved.order);
      expect(swapped.sourceName, saved.sourceName);
    });
  });
}
