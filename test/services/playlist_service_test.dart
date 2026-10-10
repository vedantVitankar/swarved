import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/content/words.dart';
import 'package:swarved/models/playlist.dart';
import 'package:swarved/models/playlist_item.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/services/playlist_service.dart';
import 'package:swarved/services/playlist_store.dart';

final _t0 = DateTime.utc(2026, 10, 11, 9);

/// A store that lives in memory and remembers every save.
class _FakeStore implements PlaylistStore {
  _FakeStore([List<Playlist> initial = const []]) : kept = List.of(initial);

  List<Playlist> kept;
  final List<List<Playlist>> writes = [];
  bool failRead = false;
  bool failWrite = false;

  @override
  Future<List<Playlist>> read() async {
    if (failRead) throw StateError('file is locked');
    return List.of(kept);
  }

  @override
  Future<void> write(List<Playlist> playlists) async {
    if (failWrite) throw StateError('disk full');
    writes.add(playlists);
    kept = playlists;
  }
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

Track _local(String title, {String path = '/music/a.mp3'}) {
  return Track(
    filePath: path,
    title: title,
    artist: 'Artist',
    album: '',
    duration: const Duration(seconds: 200),
    folder: 'music',
  );
}

Playlist _playlist(
  String id,
  String name, {
  PlaylistKind kind = PlaylistKind.user,
  List<Track> tracks = const [],
  DateTime? created,
  DateTime? deletedAt,
}) {
  final made = created ?? _t0;
  return Playlist(
    id: id,
    name: name,
    kind: kind,
    items: [
      for (final track in tracks) PlaylistItem.fromTrack(track, addedAt: _t0),
    ],
    createdAt: made,
    updatedAt: made,
    deletedAt: deletedAt,
  );
}

void main() {
  late int tick;
  late int ids;

  setUp(() {
    tick = 0;
    ids = 0;
  });

  // Every call to the clock is one minute later, so playlists made one after
  // another are made at different times.
  DateTime clock() => _t0.add(Duration(minutes: tick++));

  PlaylistService serviceOver(_FakeStore store) {
    return PlaylistService(
      store: store,
      clock: clock,
      newId: () => 'pl_${++ids}',
    );
  }

  Future<PlaylistService> loaded([_FakeStore? store]) async {
    final service = serviceOver(store ?? _FakeStore());
    await service.load();
    return service;
  }

  List<String> keysOf(PlaylistService service, String id) =>
      [for (final item in service.byId(id)!.items) item.key];

  group('load', () {
    test('makes Liked songs when there is nothing yet, and saves it', () async {
      final store = _FakeStore();
      final service = await loaded(store);
      await service.saved;

      expect(service.playlists, hasLength(1));
      expect(service.liked.id, Playlist.likedId);
      expect(service.liked.name, Words.likedSongs);
      expect(service.liked.kind, PlaylistKind.liked);
      expect(store.writes, hasLength(1));
    });

    test('keeps what is on file and saves nothing new', () async {
      final store = _FakeStore([
        _playlist(Playlist.likedId, 'Liked songs', kind: PlaylistKind.liked),
        _playlist('pl_a', 'Road trip', tracks: [_youtube('a')]),
      ]);

      final service = await loaded(store);
      await service.saved;

      expect(service.playlists.map((p) => p.id), [Playlist.likedId, 'pl_a']);
      expect(store.writes, isEmpty);
    });

    test('adds Liked songs when the file has playlists but not that one',
        () async {
      final store = _FakeStore([_playlist('pl_a', 'Road trip')]);

      final service = await loaded(store);
      await service.saved;

      expect(service.playlists.first.id, Playlist.likedId);
      expect(service.byId('pl_a'), isNotNull);
      expect(store.writes, hasLength(1));
    });

    test('Liked songs on file is always liked and never deleted', () async {
      final store = _FakeStore([
        _playlist(
          Playlist.likedId,
          'Renamed on another device',
          kind: PlaylistKind.user,
          deletedAt: _t0,
        ),
      ]);

      final service = await loaded(store);

      expect(service.liked.kind, PlaylistKind.liked);
      expect(service.liked.isDeleted, isFalse);
      expect(service.playlists, hasLength(1));
    });

    test('lets go of a playlist deleted more than 30 days ago', () async {
      final now = DateTime.utc(2026, 12, 1);
      final store = _FakeStore([
        _playlist(Playlist.likedId, 'Liked', kind: PlaylistKind.liked),
        _playlist('old', 'Old', deletedAt: now.subtract(const Duration(days: 31))),
        _playlist('recent', 'Recent',
            deletedAt: now.subtract(const Duration(days: 5))),
      ]);
      final service = PlaylistService(store: store, clock: () => now);

      await service.load();
      await service.saved;

      expect(service.everything.map((p) => p.id), [Playlist.likedId, 'recent']);
      expect(store.writes, hasLength(1));
    });

    test('a playlist id that appears twice is kept once', () async {
      final store = _FakeStore([
        _playlist(Playlist.likedId, 'Liked', kind: PlaylistKind.liked),
        _playlist('pl_a', 'First'),
        _playlist('pl_a', 'Second'),
      ]);

      final service = await loaded(store);

      expect(service.byId('pl_a')!.name, 'First');
    });

    test('a file that cannot be read still works, but nothing is saved',
        () async {
      final store = _FakeStore()..failRead = true;
      final service = await loaded(store);

      service.create('Road trip');
      await service.saved;

      expect(service.liked, isNotNull);
      expect(service.playlists, hasLength(2));
      expect(store.writes, isEmpty);
    });

    test('liked works before load, as an empty one', () {
      final service = serviceOver(_FakeStore());

      expect(service.liked.items, isEmpty);
      expect(service.isLiked(_youtube('a')), isFalse);
    });
  });

  group('reading', () {
    test('Liked songs first, then the newest made first', () async {
      final service = await loaded();
      final first = service.create('First')!;
      final second = service.create('Second')!;

      expect(service.playlists.map((p) => p.id), [
        Playlist.likedId,
        second.id,
        first.id,
      ]);
    });

    test('deleted playlists are hidden but still on file', () async {
      final service = await loaded();
      final made = service.create('Gone')!;
      service.delete(made.id);

      expect(service.byId(made.id), isNull);
      expect(service.playlists.map((p) => p.id), isNot(contains(made.id)));
      expect(service.everything.map((p) => p.id), contains(made.id));
    });

    test('says which playlists a song is in', () async {
      final service = await loaded();
      final road = service.create('Road')!;
      final other = service.create('Other')!;
      final song = _youtube('a');
      service.add(Playlist.likedId, song);
      service.add(road.id, song);

      expect(
        service.playlistIdsWith(song),
        {Playlist.likedId, road.id},
      );
      expect(service.playlistIdsWith(song), isNot(contains(other.id)));
      expect(service.isLiked(song), isTrue);
      expect(service.isLiked(_youtube('b')), isFalse);
    });

    test('a local song counts as in a playlist from another device', () async {
      final service = await loaded();
      final onPhone = _local('Tum Hi Ho', path: '/phone/tum.mp3');
      final onComputer = _local('Tum Hi Ho', path: r'D:\tum.mp3');
      service.add(Playlist.likedId, onPhone);

      expect(service.isLiked(onComputer), isTrue);
    });
  });

  group('create, rename, delete, restore', () {
    test('create trims the name and gives it an id', () async {
      final service = await loaded();

      final made = service.create('  Road   trip ')!;

      expect(made.name, 'Road trip');
      expect(made.kind, PlaylistKind.user);
      expect(made.items, isEmpty);
      expect(service.byId(made.id), isNotNull);
    });

    test('create refuses an empty name', () async {
      final service = await loaded();
      var told = 0;
      service.addListener(() => told++);

      expect(service.create('   '), isNull);
      expect(service.playlists, hasLength(1));
      expect(told, 0);
    });

    test('rename changes a playlist of hers', () async {
      final service = await loaded();
      final made = service.create('Old')!;

      expect(service.rename(made.id, ' New  name '), isTrue);
      expect(service.byId(made.id)!.name, 'New name');
    });

    test('rename says no to Liked songs, an empty name, or the same name',
        () async {
      final service = await loaded();
      final made = service.create('Same')!;

      expect(service.rename(Playlist.likedId, 'Mine'), isFalse);
      expect(service.liked.name, Words.likedSongs);
      expect(service.rename(made.id, '  '), isFalse);
      expect(service.rename(made.id, 'Same'), isFalse);
      expect(service.rename('nope', 'x'), isFalse);
    });

    test('rename says no to one he sent', () async {
      final store = _FakeStore([
        _playlist('sent', 'For you', kind: PlaylistKind.pushed),
      ]);
      final service = await loaded(store);

      expect(service.rename('sent', 'Mine'), isFalse);
    });

    test('delete hides it and restore brings it back with its songs',
        () async {
      final service = await loaded();
      final made = service.create('Road')!;
      service.add(made.id, _youtube('a'));

      expect(service.delete(made.id), isTrue);
      expect(service.byId(made.id), isNull);
      expect(service.everything.firstWhere((p) => p.id == made.id).isDeleted,
          isTrue);

      expect(service.restore(made.id), isTrue);
      expect(keysOf(service, made.id), ['yt:a']);
    });

    test('Liked songs and one he sent cannot be deleted', () async {
      final store = _FakeStore([
        _playlist('sent', 'For you', kind: PlaylistKind.pushed),
      ]);
      final service = await loaded(store);

      expect(service.delete(Playlist.likedId), isFalse);
      expect(service.delete('sent'), isFalse);
      expect(service.delete('nope'), isFalse);
      expect(service.playlists, hasLength(2));
    });

    test('restore says no to one that is not deleted', () async {
      final service = await loaded();
      final made = service.create('Road')!;

      expect(service.restore(made.id), isFalse);
      expect(service.restore('nope'), isFalse);
    });
  });

  group('add, remove, move', () {
    test('add puts the song at the end', () async {
      final service = await loaded();

      expect(service.add(Playlist.likedId, _youtube('a')), AddResult.added);
      expect(service.add(Playlist.likedId, _youtube('b')), AddResult.added);

      expect(keysOf(service, Playlist.likedId), ['yt:a', 'yt:b']);
    });

    test('a song is in a playlist once', () async {
      final service = await loaded();
      service.add(Playlist.likedId, _youtube('a'));

      expect(
        service.add(Playlist.likedId, _youtube('a')),
        AddResult.alreadyThere,
      );
      expect(keysOf(service, Playlist.likedId), ['yt:a']);
    });

    test('two copies of one local song are one song', () async {
      final service = await loaded();
      service.add(Playlist.likedId, _local('Twin', path: '/one/twin.mp3'));

      expect(
        service.add(Playlist.likedId, _local('Twin', path: '/two/twin.mp3')),
        AddResult.alreadyThere,
      );
    });

    test('add says so when there is no such playlist, or it is read only',
        () async {
      final store = _FakeStore([
        _playlist('sent', 'For you', kind: PlaylistKind.pushed),
      ]);
      final service = await loaded(store);

      expect(service.add('nope', _youtube('a')), AddResult.noSuchPlaylist);
      expect(service.add('sent', _youtube('a')), AddResult.noSuchPlaylist);
    });

    test('add keeps a snapshot of the song', () async {
      final service = await loaded();
      service.add(Playlist.likedId, _youtube('a'));

      final item = service.liked.items.single;

      expect(item.title, 'Online a');
      expect(item.artist, 'Chan');
      expect(item.duration, const Duration(seconds: 120));
      expect(item.artworkUrl, 'https://x/a.jpg');
    });

    test('remove takes a song out and leaves the rest in order', () async {
      final service = await loaded();
      for (final id in ['a', 'b', 'c']) {
        service.add(Playlist.likedId, _youtube(id));
      }

      expect(service.remove(Playlist.likedId, 'yt:b'), isTrue);
      expect(keysOf(service, Playlist.likedId), ['yt:a', 'yt:c']);
      expect(service.remove(Playlist.likedId, 'yt:b'), isFalse);
      expect(service.remove('nope', 'yt:a'), isFalse);
    });

    test('move puts a song where it is told, down or up', () async {
      final service = await loaded();
      for (final id in ['a', 'b', 'c']) {
        service.add(Playlist.likedId, _youtube(id));
      }

      expect(service.move(Playlist.likedId, 0, 2), isTrue);
      expect(keysOf(service, Playlist.likedId), ['yt:b', 'yt:c', 'yt:a']);

      expect(service.move(Playlist.likedId, 2, 0), isTrue);
      expect(keysOf(service, Playlist.likedId), ['yt:a', 'yt:b', 'yt:c']);
    });

    test('move refuses places that are not there, or no move at all',
        () async {
      final service = await loaded();
      service.add(Playlist.likedId, _youtube('a'));
      service.add(Playlist.likedId, _youtube('b'));

      expect(service.move(Playlist.likedId, 0, 0), isFalse);
      expect(service.move(Playlist.likedId, -1, 1), isFalse);
      expect(service.move(Playlist.likedId, 0, 2), isFalse);
      expect(service.move(Playlist.likedId, 5, 0), isFalse);
      expect(service.move('nope', 0, 1), isFalse);
      expect(keysOf(service, Playlist.likedId), ['yt:a', 'yt:b']);
    });
  });

  group('toggleLiked (the heart held down)', () {
    test('likes a song, then unlikes it, and says which', () async {
      final service = await loaded();

      expect(service.toggleLiked(_youtube('a')), isTrue);
      expect(service.isLiked(_youtube('a')), isTrue);

      expect(service.toggleLiked(_youtube('a')), isFalse);
      expect(service.isLiked(_youtube('a')), isFalse);
    });

    test('leaves the rest of Liked songs alone', () async {
      final service = await loaded();
      service.add(Playlist.likedId, _youtube('a'));
      service.add(Playlist.likedId, _youtube('b'));
      service.add(Playlist.likedId, _youtube('c'));

      service.toggleLiked(_youtube('b'));

      expect(keysOf(service, Playlist.likedId), ['yt:a', 'yt:c']);
    });

    test('says no before the playlists are loaded', () {
      final service = serviceOver(_FakeStore());

      expect(service.toggleLiked(_youtube('a')), isFalse);
    });
  });

  group('applyMembership (the Done button)', () {
    test('adds to the ticked playlists and removes from the cleared ones',
        () async {
      final service = await loaded();
      final road = service.create('Road')!;
      final rain = service.create('Rain')!;
      final song = _youtube('a');
      service.add(road.id, song);

      service.applyMembership(song, playlistIds: {rain.id, Playlist.likedId});

      expect(service.playlistIdsWith(song), {rain.id, Playlist.likedId});
      expect(keysOf(service, road.id), isEmpty);
    });

    test('a song taken out and put back before Done keeps its place',
        () async {
      final service = await loaded();
      final road = service.create('Road')!;
      final songs = [_youtube('a'), _youtube('b'), _youtube('c')];
      for (final song in songs) {
        service.add(road.id, song);
      }
      final before = service.byId(road.id)!;

      // She cleared the tick on B and ticked it again, so Done is told that
      // B is still in Road.
      service.applyMembership(songs[1], playlistIds: {road.id});

      expect(identical(service.byId(road.id), before), isTrue);
      expect(keysOf(service, road.id), ['yt:a', 'yt:b', 'yt:c']);
    });

    test('a song added to a playlist goes to the end', () async {
      final service = await loaded();
      final road = service.create('Road')!;
      service.add(road.id, _youtube('a'));
      service.add(road.id, _youtube('b'));

      service.applyMembership(_youtube('c'), playlistIds: {road.id});

      expect(keysOf(service, road.id), ['yt:a', 'yt:b', 'yt:c']);
    });

    test('new names make new playlists that already hold the song', () async {
      final service = await loaded();
      final song = _youtube('a');

      service.applyMembership(
        song,
        playlistIds: {},
        newNames: ['  Late   night ', 'Mornings'],
      );

      final names = service.playlists.map((p) => p.name).toList();
      expect(names, containsAll(['Late night', 'Mornings']));
      for (final playlist in service.playlists.where((p) => !p.isLiked)) {
        expect(playlist.contains('yt:a'), isTrue);
      }
    });

    test('an empty new name is ignored', () async {
      final service = await loaded();

      service.applyMembership(
        _youtube('a'),
        playlistIds: {},
        newNames: ['   '],
      );

      expect(service.playlists, hasLength(1));
    });

    test('ids that are not playlists, and ones he sent, are ignored',
        () async {
      final store = _FakeStore([
        _playlist('sent', 'For you', kind: PlaylistKind.pushed),
      ]);
      final service = await loaded(store);

      service.applyMembership(_youtube('a'), playlistIds: {'sent', 'nope'});

      expect(service.byId('sent')!.items, isEmpty);
      expect(service.playlistIdsWith(_youtube('a')), isEmpty);
    });

    test('when nothing changes nobody is told and nothing is saved',
        () async {
      final store = _FakeStore();
      final service = await loaded(store);
      await service.saved;
      final savesBefore = store.writes.length;
      var told = 0;
      service.addListener(() => told++);

      service.applyMembership(_youtube('a'), playlistIds: {});
      await service.saved;

      expect(told, 0);
      expect(store.writes.length, savesBefore);
    });

    test('one Done is one notification and one save', () async {
      final store = _FakeStore();
      final service = await loaded(store);
      final road = service.create('Road')!;
      await service.saved;
      final savesBefore = store.writes.length;
      var told = 0;
      service.addListener(() => told++);

      service.applyMembership(
        _youtube('a'),
        playlistIds: {road.id, Playlist.likedId},
        newNames: ['Fresh'],
      );
      await service.saved;

      expect(told, 1);
      expect(store.writes.length, savesBefore + 1);
    });
  });

  group('saving', () {
    test('every change tells listeners', () async {
      final service = await loaded();
      var told = 0;
      service.addListener(() => told++);

      final made = service.create('Road')!;
      service.add(made.id, _youtube('a'));
      service.rename(made.id, 'Road 2');
      service.remove(made.id, 'yt:a');
      service.delete(made.id);
      service.restore(made.id);

      expect(told, 6);
    });

    test('a quick run of changes ends with the newest state on file',
        () async {
      final store = _FakeStore();
      final service = await loaded(store);

      final made = service.create('Road')!;
      service.add(made.id, _youtube('a'));
      service.add(made.id, _youtube('b'));
      service.rename(made.id, 'Road trip');
      await service.saved;

      final onFile = store.kept.firstWhere((p) => p.id == made.id);
      expect(onFile.name, 'Road trip');
      expect([for (final i in onFile.items) i.key], ['yt:a', 'yt:b']);
    });

    test('what is saved loads back the same', () async {
      final store = _FakeStore();
      final first = await loaded(store);
      final made = first.create('Road')!;
      first.add(made.id, _youtube('a'));
      first.add(Playlist.likedId, _local('Tum Hi Ho'));
      await first.saved;

      final second = await loaded(store);

      expect(keysOf(second, made.id), ['yt:a']);
      expect(second.isLiked(_local('Tum Hi Ho', path: '/elsewhere.mp3')),
          isTrue);
    });

    test('a failed save is survived, and the next one works', () async {
      final store = _FakeStore();
      final service = await loaded(store);
      await service.saved;

      store.failWrite = true;
      service.create('Lost for now');
      await service.saved;

      store.failWrite = false;
      service.create('Kept');
      await service.saved;

      final names = store.kept.map((p) => p.name);
      expect(names, containsAll(['Lost for now', 'Kept']));
    });

    test('a change after dispose does not throw', () async {
      final service = await loaded();
      service.dispose();

      expect(() => service.create('Late'), returnsNormally);
    });
  });
}
