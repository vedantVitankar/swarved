import '../models/playlist.dart';

/// What a Home tile opens.
enum HomeTileKind { playlist, folder }

/// One tile of the Home grid: a playlist or a folder.
class HomeTile {
  /// [id] is the playlist's id.
  HomeTile.playlist(Playlist playlist)
      : kind = HomeTileKind.playlist,
        id = playlist.id,
        name = playlist.name,
        isLiked = playlist.isLiked;

  /// [id] is the folder's name, which is what the library keys folders by.
  HomeTile.folder(String folder)
      : kind = HomeTileKind.folder,
        id = folder,
        name = folder,
        isLiked = false;

  final HomeTileKind kind;
  final String id;
  final String name;
  final bool isLiked;
}

/// The grid on Home: two columns by three rows.
const int homeTileSlots = 6;

/// How many of those may be playlists before folders get their turn.
const int homeTilePlaylistShare = 3;

/// Chooses what fills the Home grid. Liked songs is always first, then her
/// newest playlists up to [playlistShare], then folders in the order given
/// (most recently played first). If folders run out, more playlists fill the
/// rest, so the grid is as full as her library allows.
///
/// [playlists] come as the service lists them: Liked songs first, then the
/// newest made first.
List<HomeTile> pickHomeTiles({
  required List<Playlist> playlists,
  required List<String> foldersByRecency,
  int slots = homeTileSlots,
  int playlistShare = homeTilePlaylistShare,
}) {
  final tiles = <HomeTile>[
    for (final playlist in playlists.take(playlistShare))
      HomeTile.playlist(playlist),
  ];

  for (final folder in foldersByRecency) {
    if (tiles.length >= slots) break;
    tiles.add(HomeTile.folder(folder));
  }

  for (final playlist in playlists.skip(playlistShare)) {
    if (tiles.length >= slots) break;
    tiles.add(HomeTile.playlist(playlist));
  }

  return tiles.take(slots).toList();
}
