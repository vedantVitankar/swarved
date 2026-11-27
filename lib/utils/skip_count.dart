/// Whether a skip counts as a song for the voice recordings, which play
/// "after so many songs". A song that ends by itself always counts. A skip
/// counts when she was really listening to a song and moves to a different
/// one: the next button, a tap on another song, or starting another
/// playlist.
///
/// - [listening]: a song of hers was loaded and playing or paused. False
///   for a voice recording, a letter's recording, a queue restored when the
///   app opened and not started yet, a song that failed to load, and when
///   nothing is playing.
/// - [playingId] and [chosenId]: the song she leaves and the one she goes
///   to. The same song again (a restart, a tap on the song that is playing)
///   is not a skip.
bool skipCounts({
  required bool listening,
  required String? playingId,
  required String? chosenId,
}) {
  if (!listening || playingId == null || chosenId == null) return false;
  return playingId != chosenId;
}
