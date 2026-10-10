/// Where the queue now playing came from, for the "Playing from ..." line.
/// Only playlists name themselves. A folder or a search plays without one,
/// and Now Playing words those from the song.
class PlaySource {
  const PlaySource(this.name);

  final String name;
}
