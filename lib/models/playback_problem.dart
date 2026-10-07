/// Why a song isn't playing. One value per thing the listener can act on.
enum PlaybackProblem {
  /// No token is saved, so the server can't be asked.
  noToken,

  /// The server rejected the saved token.
  unauthorized,

  /// The video is gone, private, or blocked.
  unavailable,

  /// The server could not be reached.
  unreachable,

  /// The server took too long to answer.
  timeout,

  /// The connection dropped while the song was playing.
  connectionLost,

  /// The server could not get the song from YouTube just now.
  serverTrouble,

  /// Anything else.
  unexpected,
}
