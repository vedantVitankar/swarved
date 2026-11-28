import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/playlist.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/services/playlist_service.dart';
import 'package:swarved/services/playlist_store.dart';

class _Store implements PlaylistStore {
  List<Playlist> kept = const [];
  int writes = 0;

  @override
  Future<List<Playlist>> read() async => List.of(kept);

  @override
  Future<void> write(List<Playlist> playlists) async {
    writes++;
    kept = playlists;
  }
}

Track _youtube(String id) => Track.youtube(
      videoId: id,
      title: 'Online $id',
      artist: 'Chan',
      duration: const Duration(seconds: 120),
    );

void main() {
  late _Store store;
  late PlaylistService service;
  var ids = 0;

  setUp(() async {
    ids = 0;
    store = _Store();
    service = PlaylistService(store: store, newId: () => 'pl_${++ids}');
    await service.load();
  });

  group('PlaylistService.createWith', () {
    test('makes the playlist with its songs in order', () {
      final created = service.createWith('Rain', [
        _youtube('aaaaaaaaaaa'),
        _youtube('bbbbbbbbbbb'),
        _youtube('ccccccccccc'),
      ])!;
      expect(created.name, 'Rain');
      expect(
        [for (final item in service.byId(created.id)!.items) item.key],
        ['yt:aaaaaaaaaaa', 'yt:bbbbbbbbbbb', 'yt:ccccccccccc'],
      );
      expect(service.byId(created.id)!.kind, PlaylistKind.user);
    });

    test('a song given twice is in once', () {
      final created = service.createWith('Rain', [
        _youtube('aaaaaaaaaaa'),
        _youtube('bbbbbbbbbbb'),
        _youtube('aaaaaaaaaaa'),
      ])!;
      expect(created.items.length, 2);
    });

    test('an empty name makes nothing', () {
      final before = service.playlists.length;
      expect(service.createWith('   ', [_youtube('aaaaaaaaaaa')]), isNull);
      expect(service.playlists.length, before);
    });

    test('tells listeners once and saves once, however many songs', () async {
      await service.saved;
      final writesBefore = store.writes;
      var told = 0;
      service.addListener(() => told++);
      service.createWith('Big', [
        for (var i = 0; i < 100; i++) _youtube('id${i.toString().padLeft(9, '0')}'),
      ]);
      await service.saved;
      expect(told, 1);
      expect(store.writes - writesBefore, 1);
      expect(store.kept.last.items.length, 100);
    });

    test('Liked songs and her other playlists are not touched', () {
      final first = service.create('Mine')!;
      service.add(first.id, _youtube('zzzzzzzzzzz'));
      service.createWith('Imported', [_youtube('aaaaaaaaaaa')]);
      expect(service.byId(first.id)!.items.length, 1);
      expect(service.liked.items, isEmpty);
    });
  });
}
