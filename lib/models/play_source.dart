/// Where the queue now playing came from, for the "Playing from ..." line.
/// Only playlists name themselves. A folder or a search plays without one,
/// and Now Playing words those from the song.
class PlaySource {
  const PlaySource(this.name, {this.playlistId});

  final String name;

  /// The playlist's id, so the queue can say where it came from again after
  /// the app has been closed and the queue put back.
  final String? playlistId;
}
