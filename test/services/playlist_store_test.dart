import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:swarved/models/playlist.dart';
import 'package:swarved/models/playlist_item.dart';
import 'package:swarved/services/playlist_store.dart';

final _t0 = DateTime.utc(2026, 10, 11, 9);

Playlist _playlist(String id, String name, List<String> keys) {
  return Playlist(
    id: id,
    name: name,
    kind: PlaylistKind.user,
    items: [
      for (final key in keys)
        PlaylistItem(
          key: key,
          title: 'T $key',
          artist: 'A',
          duration: const Duration(seconds: 100),
          addedAt: _t0,
        ),
    ],
    createdAt: _t0,
    updatedAt: _t0,
  );
}

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('swarved_playlists_test');
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  FilePlaylistStore store() => FilePlaylistStore(directory: () async => dir);

  List<String> files() =>
      dir.listSync().map((entry) => p.basename(entry.path)).toList()..sort();

  File mainFile() => File(p.join(dir.path, FilePlaylistStore.fileName));

  group('FilePlaylistStore', () {
    test('has nothing before anything is saved', () async {
      expect(await store().read(), isEmpty);
    });

    test('gives back what was saved, in order', () async {
      await store().write([
        _playlist('pl_1', 'One', ['yt:a', 'local:b']),
        _playlist('pl_2', 'Two', []),
      ]);

      final back = await store().read();

      expect([for (final x in back) x.id], ['pl_1', 'pl_2']);
      expect([for (final i in back.first.items) i.key], ['yt:a', 'local:b']);
      expect(back.first.name, 'One');
    });

    test('makes the folder when it is not there yet', () async {
      final deep = Directory(p.join(dir.path, 'a', 'b'));
      final deepStore = FilePlaylistStore(directory: () async => deep);

      await deepStore.write([_playlist('pl_1', 'One', [])]);

      expect(await deepStore.read(), hasLength(1));
    });

    test('leaves no temporary file behind', () async {
      await store().write([_playlist('pl_1', 'One', [])]);
      await store().write([_playlist('pl_1', 'One', ['yt:a'])]);

      expect(files(), isNot(contains('${FilePlaylistStore.fileName}.tmp')));
    });

    test('writes a version number', () async {
      await store().write([_playlist('pl_1', 'One', [])]);

      final document = jsonDecode(await mainFile().readAsString()) as Map;

      expect(document['version'], FilePlaylistStore.version);
    });

    test('keeps the version before as a copy', () async {
      await store().write([_playlist('pl_1', 'First', [])]);
      await store().write([_playlist('pl_1', 'Second', [])]);

      final previous = File('${mainFile().path}.prev');
      final document = jsonDecode(await previous.readAsString()) as Map;

      expect((document['playlists'] as List).single['name'], 'First');
    });

    test('a damaged file falls back to the copy, and is kept aside', () async {
      await store().write([_playlist('pl_1', 'First', [])]);
      await store().write([_playlist('pl_1', 'Second', [])]);
      await mainFile().writeAsString('{ this is not json');

      final back = await store().read();

      expect(back.single.name, 'First');
      expect(files().where((f) => f.contains('.damaged-')), hasLength(1));
    });

    test('a damaged file and no copy gives nothing, but is kept', () async {
      await mainFile().writeAsString('garbage');

      expect(await store().read(), isEmpty);
      expect(files().where((f) => f.contains('.damaged-')), hasLength(1));
    });

    test('a file of the wrong shape counts as damaged', () async {
      await mainFile().writeAsString('{"playlists": 5}');

      expect(await store().read(), isEmpty);
      expect(files().where((f) => f.contains('.damaged-')), hasLength(1));
    });

    test('a damaged copy as well gives nothing and is kept', () async {
      await File('${mainFile().path}.prev').writeAsString('also garbage');

      expect(await store().read(), isEmpty);
      expect(files().where((f) => f.contains('.damaged-')), hasLength(1));
    });

    test('one bad playlist does not spoil the others', () async {
      await mainFile().writeAsString(jsonEncode({
        'version': 1,
        'playlists': [
          _playlist('pl_1', 'Good', ['yt:a']).toJson(),
          {'name': 'no id'},
          _playlist('pl_2', 'Also good', []).toJson(),
        ],
      }));

      final back = await store().read();

      expect([for (final x in back) x.name], ['Good', 'Also good']);
    });
  });
}
