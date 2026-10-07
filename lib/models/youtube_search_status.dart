/// Where the YouTube half of a search stands.
enum YoutubeSearchStatus {
  /// Nothing typed.
  idle,

  /// Waiting for a pause in typing, or for the server's answer.
  loading,

  /// The server answered (the list may still be empty).
  loaded,

  /// No token saved, or the server rejected it.
  unauthorized,

  /// The server could not be reached, or gave up.
  unreachable,

  /// The server answered, but not in the expected shape.
  unexpected,
}
