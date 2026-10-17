import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/playlist.dart';
import 'package:swarved/models/playlist_item.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/services/playlist_service.dart';
import 'package:swarved/services/playlist_store.dart';

class _Store implements PlaylistStore {
  List<Playlist> kept = [];
  @override
  Future<List<Playlist>> read() async => List.of(kept);
  @override
  Future<void> write(List<Playlist> playlists) async => kept = playlists;
}

Track _songTrack(String id) => Track.youtube(
      videoId: id,
      title: 'Song $id',
      artist: 'Artist',
      duration: const Duration(seconds: 100),
    );

final _now = DateTime.utc(2026, 10, 15, 12);
DateTime _ago(int hours) => _now.subtract(Duration(hours: hours));

PlaylistItem _song(String id) => PlaylistItem(
      key: 'yt:$id',
      title: 'Song $id',
      artist: 'Artist',
      duration: const Duration(seconds: 100),
      addedAt: _ago(50),
    );

Playlist _list(
  String id,
  String name,
  List<String> songs, {
  required DateTime updated,
  DateTime? created,
  DateTime? deleted,
  PlaylistKind kind = PlaylistKind.user,
}) {
  return Playlist(
    id: id,
    name: name,
    kind: id == Playlist.likedId ? PlaylistKind.liked : kind,
    items: [for (final s in songs) _song(s)],
    createdAt: created ?? _ago(100),
    updatedAt: updated,
    deletedAt: deleted,
  );
}

void main() {
  late _Store store;
  late PlaylistService service;

  setUp(() async {
    store = _Store();
    service = PlaylistService(store: store, clock: () => _now);
    await service.load();
  });

  tearDown(() => service.dispose());

  List<String> keys(String id) =>
      [for (final item in service.byId(id)!.items) item.key];

  group('mergeRemote', () {
    test('a playlist from another device is added', () async {
      final changed = service.mergeRemote([
        _list('pl_1', 'Slow dances', ['aaaaaaaaaaa'], updated: _ago(5)),
      ]);
      await service.saved;

      expect(changed, isTrue);
      expect(service.byId('pl_1')!.name, 'Slow dances');
      expect(keys('pl_1'), ['yt:aaaaaaaaaaa']);
      expect(store.kept.any((p) => p.id == 'pl_1'), isTrue,
          reason: 'it is saved on this device too');
    });

    test('the copy edited last wins, in both directions', () {
      service.mergeRemote([
        _list('pl_1', 'Old name', ['aaaaaaaaaaa'], updated: _ago(10)),
      ]);

      service.mergeRemote([
        _list('pl_1', 'Newer', ['aaaaaaaaaaa', 'bbbbbbbbbbb'],
            updated: _ago(5)),
      ]);
      expect(service.byId('pl_1')!.name, 'Newer');
      expect(keys('pl_1'), ['yt:aaaaaaaaaaa', 'yt:bbbbbbbbbbb']);

      final changed = service.mergeRemote([
        _list('pl_1', 'Stale', ['ccccccccccc'], updated: _ago(20)),
      ]);
      expect(changed, isFalse);
      expect(service.byId('pl_1')!.name, 'Newer');
    });

    test('the same thing twice changes nothing', () {
      final remote = [
        _list('pl_1', 'Slow dances', ['aaaaaaaaaaa'], updated: _ago(5)),
      ];
      expect(service.mergeRemote(remote), isTrue);
      expect(service.mergeRemote(remote), isFalse);
    });

    test('a playlist deleted on another device is deleted here', () {
      service.mergeRemote([
        _list('pl_1', 'Slow dances', ['aaaaaaaaaaa'], updated: _ago(10)),
      ]);
      service.mergeRemote([
        _list('pl_1', 'Slow dances', ['aaaaaaaaaaa'],
            updated: _ago(3), deleted: _ago(3)),
      ]);
      expect(service.byId('pl_1'), isNull);
      expect(service.playlists.any((p) => p.id == 'pl_1'), isFalse);
      expect(service.everything.any((p) => p.id == 'pl_1'), isTrue,
          reason: 'the marker is kept so it can be passed on');
    });

    test('an older delete does not remove a playlist edited since', () {
      service.mergeRemote([
        _list('pl_1', 'Slow dances', ['aaaaaaaaaaa'], updated: _ago(2)),
      ]);
      service.mergeRemote([
        _list('pl_1', 'Slow dances', ['aaaaaaaaaaa'],
            updated: _ago(8), deleted: _ago(8)),
      ]);
      expect(service.byId('pl_1'), isNotNull);
    });

    test('a delete from long ago is not taken in for an unknown playlist', () {
      final changed = service.mergeRemote([
        _list('pl_old', 'Gone', [],
            updated: _now.subtract(const Duration(days: 40)),
            deleted: _now.subtract(const Duration(days: 40))),
      ]);
      expect(changed, isFalse);
      expect(service.everything.any((p) => p.id == 'pl_old'), isFalse);
    });

    test('a fresh install\'s empty Liked songs takes the real one', () {
      // This device only has the blank Liked songs that load() made.
      expect(service.liked.items, isEmpty);
      service.mergeRemote([
        _list(Playlist.likedId, 'Liked songs', ['aaaaaaaaaaa', 'bbbbbbbbbbb'],
            updated: _ago(30)),
      ]);
      expect(service.liked.items, hasLength(2));
      expect(service.liked.kind, PlaylistKind.liked);
    });

    test('a blank Liked songs from elsewhere never empties a real one', () {
      service.toggleLiked(
        _songTrack('aaaaaaaaaaa'),
      );
      final changed = service.mergeRemote([
        _list(Playlist.likedId, 'Liked songs', [],
            updated: _ago(1), created: _ago(1)),
      ]);
      expect(changed, isFalse);
      expect(service.liked.items, hasLength(1));
    });

    test('Liked songs is never deleted by a marker', () {
      service.toggleLiked(_songTrack('aaaaaaaaaaa'));
      service.mergeRemote([
        _list(Playlist.likedId, 'Liked songs', ['aaaaaaaaaaa'],
            updated: _now.add(const Duration(hours: 1)),
            deleted: _now.add(const Duration(hours: 1))),
      ]);
      expect(service.liked.isDeleted, isFalse);
    });

    test('his pushed playlists are never taken from the server', () {
      final changed = service.mergeRemote([
        _list('pl_p', 'From him', ['aaaaaaaaaaa'],
            updated: _ago(1), kind: PlaylistKind.pushed),
      ]);
      expect(changed, isFalse);
      expect(service.byId('pl_p'), isNull);
    });

    test('what comes in is hers: a user playlist she can edit', () {
      service.mergeRemote([
        _list('pl_1', 'Slow dances', ['aaaaaaaaaaa'], updated: _ago(5)),
      ]);
      expect(service.byId('pl_1')!.kind, PlaylistKind.user);
      expect(service.byId('pl_1')!.isEditable, isTrue);
    });

    test('listeners hear about a change, and only a change', () {
      var heard = 0;
      service.addListener(() => heard++);
      final remote = [
        _list('pl_1', 'Slow dances', ['aaaaaaaaaaa'], updated: _ago(5)),
      ];
      service.mergeRemote(remote);
      expect(heard, 1);
      service.mergeRemote(remote);
      expect(heard, 1);
    });
  });
}
