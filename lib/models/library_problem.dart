/// Why a library couldn't be opened. The empty screen turns each case
/// into a message; the service itself never deals in wording.
enum LibraryProblem {
  /// Android's permission to read audio files was not given.
  noPermission,

  /// The chosen folder can't be opened.
  unreadableFolder,

  /// The folder opened, but holds no supported audio files.
  noAudioFound,
}
