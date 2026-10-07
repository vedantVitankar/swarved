/// How much the server should do ahead of time for a song.
enum PrefetchMode {
  /// Only look up where the song's audio is. Cheap, and it saves the
  /// two-second wait when the song is played. Nothing is downloaded.
  resolve,

  /// Also download the whole song into the server's cache.
  full,
}
