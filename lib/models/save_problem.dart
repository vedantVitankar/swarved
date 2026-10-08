/// Why a song could not be saved. One value per thing the listener can act on.
enum SaveProblem {
  /// No token is saved, so the server can't be asked.
  noToken,

  /// The server rejected the saved token.
  unauthorized,

  /// The video is gone, private, or blocked.
  unavailable,

  /// The server is busy converting other songs.
  serverBusy,

  /// The server could not prepare the song just now.
  serverTrouble,

  /// The server could not be reached.
  unreachable,

  /// The server took too long to answer.
  timeout,

  /// The connection dropped while the song was coming down.
  connectionLost,

  /// The folder to save into is gone.
  folderMissing,

  /// The phone or computer refuses writes to the folder.
  cannotWrite,

  /// There is no room left on the device.
  diskFull,

  /// Anything else.
  unexpected,
}
