import '../models/track.dart';
import '../utils/playlist_resolve.dart';
import 'player_service.dart';
import 'playlist_service.dart';

/// Keeps the queue now playing in step with the playlist it came from: a song
/// added, taken out or moved while the playlist plays shows up in the queue
/// at once, without stopping the song.
///
/// It only listens to the playlists and hands the player the playlist as it
/// is now. How the queue is changed is [PlayerService.syncQueue]'s business.
/// A folder, a search or a single song has no playlist, so nothing happens.
class PlaylistQueueFollower {
  PlaylistQueueFollower({
    required this.player,
    required this.playlists,
    required this.libraryTracks,
  });

  final PlayerService player;
  final PlaylistService playlists;

  /// The songs found in her music folders, to find a playlist's local songs.
  final List<Track> Function() libraryTracks;

  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    playlists.addListener(_check);
  }

  void dispose() {
    playlists.removeListener(_check);
    _started = false;
  }

  void _check() {
    final id = player.source?.playlistId;
    if (id == null) return;
    // Deleted (or not there any more): the queue plays out as it is.
    final playlist = playlists.byId(id);
    if (playlist == null) return;

    player.syncQueue(
      playableTracks(resolvePlaylist(playlist, libraryTracks())),
      inPlaylist: {for (final item in playlist.items) item.key},
      sourceName: playlist.name,
    );
  }
}
