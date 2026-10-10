import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/playlist.dart';
import 'package:swarved/models/playlist_item.dart';
import 'package:swarved/models/track.dart';

final _t0 = DateTime.utc(2026, 10, 11, 9);

PlaylistItem _item(
  String key, {
  String title = 'Title',
  int seconds = 180,
  String? art,
}) {
  return PlaylistItem(
    key: key,
    title: title,
    artist: 'Artist',
    duration: Duration(seconds: seconds),
    artworkUrl: art,
    addedAt: _t0,
  );
}

Playlist _playlist({
  String id = 'pl_1',
  String name = 'Road trip',
  PlaylistKind kind = PlaylistKind.user,
  List<PlaylistItem> items = const [],
  DateTime? deletedAt,
}) {
  return Playlist(
    id: id,
    name: name,
    kind: kind,
    items: items,
    createdAt: _t0,
    updatedAt: _t0,
    deletedAt: deletedAt,
  );
}

void main() {
  group('PlaylistItem', () {
    test('survives a trip through JSON', () {
      final item =
          _item('yt:abc', title: 'Song', seconds: 241, art: 'https://x/y.jpg');

      final back = PlaylistItem.tryParse(item.toJson())!;

      expect(back.key, 'yt:abc');
      expect(back.title, 'Song');
      expect(back.artist, 'Artist');
      expect(back.duration, const Duration(seconds: 241));
      expect(back.artworkUrl, 'https://x/y.jpg');
      expect(back.addedAt, _t0);
    });

    test('leaves out artwork it does not have', () {
      expect(_item('local:abc').toJson().containsKey('artworkUrl'), isFalse);
    });

    test('knows whether it is local or YouTube', () {
      expect(_item('local:abc').isLocal, isTrue);
      expect(_item('local:abc').isYoutube, isFalse);
      expect(_item('yt:abc').isYoutube, isTrue);
    });

    test('is skipped when its key is unusable', () {
      expect(PlaylistItem.tryParse('nope'), isNull);
      expect(PlaylistItem.tryParse({'title': 'x'}), isNull);
      expect(PlaylistItem.tryParse({'key': 5}), isNull);
      expect(PlaylistItem.tryParse({'key': '/music/a.mp3'}), isNull);
      expect(PlaylistItem.tryParse({'key': 'yt:'}), isNull);
      expect(PlaylistItem.tryParse({'key': 'local:'}), isNull);
    });

    test('falls back for details that are missing or wrong', () {
      final item = PlaylistItem.tryParse({
        'key': 'yt:abc',
        'title': 7,
        'durationSeconds': -3,
        'artworkUrl': '',
        'addedAt': 'not a date',
      })!;

      expect(item.title, '');
      expect(item.artist, '');
      expect(item.duration, Duration.zero);
      expect(item.artworkUrl, isNull);
      expect(item.addedAt, DateTime.utc(1970));
    });

    test('a YouTube item becomes a playable track', () {
      final track = _item('yt:abc', title: 'Song', seconds: 90, art: 'u')
          .toYoutubeTrack()!;

      expect(track.videoId, 'abc');
      expect(track.id, 'yt:abc');
      expect(track.title, 'Song');
      expect(track.duration, const Duration(seconds: 90));
      expect(track.artworkUrl, 'u');
    });

    test('a local item does not become a track by itself', () {
      expect(_item('local:abc').toYoutubeTrack(), isNull);
    });

    test('is made from a YouTube track with its artwork', () {
      final track = Track.youtube(
        videoId: 'abc',
        title: 'Song',
        artist: 'Chan',
        duration: const Duration(seconds: 200),
        artworkUrl: 'u',
      );

      final item = PlaylistItem.fromTrack(track, addedAt: _t0);

      expect(item.key, 'yt:abc');
      expect(item.artworkUrl, 'u');
      expect(item.addedAt, _t0);
    });

    test('is made from a local track without any artwork', () {
      final track = Track(
        filePath: '/music/a.mp3',
        title: 'Song',
        artist: 'Artist',
        album: '',
        duration: const Duration(seconds: 200),
        folder: 'music',
        artworkBytes: const [1, 2, 3],
      );

      final item = PlaylistItem.fromTrack(track, addedAt: _t0);

      expect(item.isLocal, isTrue);
      expect(item.artworkUrl, isNull);
      expect(item.title, 'Song');
    });
  });

  group('Playlist', () {
    test('survives a trip through JSON', () {
      final playlist = _playlist(
        items: [_item('yt:a'), _item('local:b')],
        deletedAt: _t0.add(const Duration(days: 1)),
      );

      final back = Playlist.tryParse(playlist.toJson())!;

      expect(back.id, 'pl_1');
      expect(back.name, 'Road trip');
      expect(back.kind, PlaylistKind.user);
      expect([for (final i in back.items) i.key], ['yt:a', 'local:b']);
      expect(back.createdAt, _t0);
      expect(back.updatedAt, _t0);
      expect(back.deletedAt, _t0.add(const Duration(days: 1)));
    });

    test('knows what is in it and how long it plays', () {
      final playlist = _playlist(
        items: [_item('yt:a', seconds: 100), _item('yt:b', seconds: 50)],
      );

      expect(playlist.contains('yt:a'), isTrue);
      expect(playlist.contains('yt:z'), isFalse);
      expect(playlist.totalDuration, const Duration(seconds: 150));
    });

    test('its songs cannot be changed behind its back', () {
      final playlist = _playlist(items: [_item('yt:a')]);

      expect(() => playlist.items.add(_item('yt:b')), throwsUnsupportedError);
    });

    test('says what can be done to it', () {
      expect(_playlist(kind: PlaylistKind.liked).isLiked, isTrue);
      expect(_playlist().isEditable, isTrue);
      expect(_playlist(kind: PlaylistKind.pushed).isEditable, isFalse);
      expect(_playlist().isDeleted, isFalse);
      expect(_playlist(deletedAt: _t0).isDeleted, isTrue);
    });

    test('copyWith changes only what it is told to', () {
      final original = _playlist(items: [_item('yt:a')]);

      final renamed = original.copyWith(name: 'New');

      expect(renamed.name, 'New');
      expect(renamed.id, original.id);
      expect(renamed.items.length, 1);
      expect(renamed.createdAt, original.createdAt);
    });

    test('copyWith can undelete', () {
      final gone = _playlist(deletedAt: _t0);

      expect(gone.copyWith(undelete: true).isDeleted, isFalse);
      expect(gone.copyWith(name: 'x').isDeleted, isTrue);
    });

    test('is skipped when it has no id or name', () {
      expect(Playlist.tryParse(5), isNull);
      expect(Playlist.tryParse({'name': 'x'}), isNull);
      expect(Playlist.tryParse({'id': '', 'name': 'x'}), isNull);
      expect(Playlist.tryParse({'id': 'a'}), isNull);
    });

    test('keeps a song once and skips the bad ones', () {
      final playlist = Playlist.tryParse({
        'id': 'pl_1',
        'name': 'x',
        'items': [
          {'key': 'yt:a', 'title': 'first'},
          {'key': 'yt:a', 'title': 'again'},
          {'key': 'bad'},
          'junk',
          {'key': 'local:b'},
        ],
      })!;

      expect([for (final i in playlist.items) i.key], ['yt:a', 'local:b']);
      expect(playlist.items.first.title, 'first');
    });

    test('an unknown kind is a playlist of hers', () {
      final playlist =
          Playlist.tryParse({'id': 'a', 'name': 'x', 'kind': 'weird'})!;

      expect(playlist.kind, PlaylistKind.user);
    });

    test('with no update time it takes the time it was made', () {
      final playlist = Playlist.tryParse({
        'id': 'a',
        'name': 'x',
        'createdAt': '2026-10-11T09:00:00.000Z',
      })!;

      expect(playlist.updatedAt, playlist.createdAt);
      expect(playlist.createdAt, _t0);
    });
  });

  group('Playlist.cleanName', () {
    test('trims and makes runs of spaces one', () {
      expect(Playlist.cleanName('  Road   trip \n'), 'Road trip');
    });

    test('is empty when nothing is left', () {
      expect(Playlist.cleanName(''), '');
      expect(Playlist.cleanName('   \t '), '');
    });

    test('is cut to the longest allowed', () {
      final cut = Playlist.cleanName('a' * 80);

      expect(cut.length, Playlist.maxNameLength);
    });

    test('is not left with a space at the end after cutting', () {
      final name = '${'a' * 59} bbbb';

      expect(Playlist.cleanName(name), 'a' * 59);
    });

    test('counts a letter outside the basic ones as one, not two', () {
      final cut = Playlist.cleanName('\u{1F600}' * 70);

      expect(cut.runes.length, Playlist.maxNameLength);
    });
  });
}
