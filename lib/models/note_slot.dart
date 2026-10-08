/// The places in the app where he can leave notes. Each slot holds a list
/// in the content file, under "slots", using the slot's name as the key.
/// One note from the list is shown at a time.
enum NoteSlot {
  /// The small gold line under the greeting on Home.
  homeLine,

  /// The note card on Home.
  homeNote,

  /// A note card on the Us tab.
  usNote,

  /// A handwritten line on the Search tab before anything is typed.
  searchNote,

  /// A note card at the top of the Library tab.
  libraryNote,

  /// Now Playing, for a song that has no note of its own.
  playingNote,

  /// Shown while a search is looking, in place of "Looking for it…".
  loading,
}
