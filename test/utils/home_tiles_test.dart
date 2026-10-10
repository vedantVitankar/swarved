import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/playlist.dart';
import 'package:swarved/utils/home_tiles.dart';

Playlist _playlist(String id, {PlaylistKind kind = PlaylistKind.user}) {
  return Playlist(
    id: id,
    name: 'Name $id',
    kind: kind,
    items: const [],
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}

Playlist get _liked =>
    _playlist(Playlist.likedId, kind: PlaylistKind.liked);

List<String> _ids(List<HomeTile> tiles) => [for (final t in tiles) t.id];

void main() {
  group('pickHomeTiles', () {
    test('fills six tiles: Liked songs, two playlists, then folders', () {
      final tiles = pickHomeTiles(
        playlists: [_liked, _playlist('p1'), _playlist('p2'), _playlist('p3')],
        foldersByRecency: ['F1', 'F2', 'F3', 'F4'],
      );
      expect(_ids(tiles), ['liked', 'p1', 'p2', 'F1', 'F2', 'F3']);
    });

    test('Liked songs is always first and knows it is liked', () {
      final tiles = pickHomeTiles(
        playlists: [_liked],
        foldersByRecency: ['F1'],
      );
      expect(tiles.first.isLiked, isTrue);
      expect(tiles.first.kind, HomeTileKind.playlist);
      expect(tiles[1].kind, HomeTileKind.folder);
      expect(tiles[1].isLiked, isFalse);
    });

    test('keeps folders in the order given', () {
      final tiles = pickHomeTiles(
        playlists: [_liked],
        foldersByRecency: ['Z', 'A', 'M'],
      );
      expect(_ids(tiles), ['liked', 'Z', 'A', 'M']);
    });

    test('more playlists fill the grid when folders run out', () {
      final tiles = pickHomeTiles(
        playlists: [
          _liked,
          _playlist('p1'),
          _playlist('p2'),
          _playlist('p3'),
          _playlist('p4'),
        ],
        foldersByRecency: ['F1'],
      );
      expect(_ids(tiles), ['liked', 'p1', 'p2', 'F1', 'p3', 'p4']);
    });

    test('never shows more than six', () {
      final tiles = pickHomeTiles(
        playlists: [for (var i = 0; i < 10; i++) _playlist('p$i')],
        foldersByRecency: [for (var i = 0; i < 10; i++) 'F$i'],
      );
      expect(tiles, hasLength(homeTileSlots));
    });

    test('shows fewer when there is little to show', () {
      expect(
        pickHomeTiles(playlists: const [], foldersByRecency: const []),
        isEmpty,
      );
      expect(
        pickHomeTiles(playlists: [_liked], foldersByRecency: const []),
        hasLength(1),
      );
    });

    test('a folder tile is keyed by its name', () {
      final tiles = pickHomeTiles(
        playlists: const [],
        foldersByRecency: ['Slow dances'],
      );
      expect(tiles.single.id, 'Slow dances');
      expect(tiles.single.name, 'Slow dances');
      expect(tiles.single.kind, HomeTileKind.folder);
    });
  });
}
