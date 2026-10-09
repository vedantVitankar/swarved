/// Why a library couldn't be opened. The Library tab turns each case into
/// a message; the service itself never deals in wording. A folder with no
/// songs in it is not a problem: songs she saves will land there.
enum LibraryProblem {
  /// Android's permission to read audio files was not given.
  noPermission,

  /// The chosen folder can't be opened.
  unreadableFolder,
}
