import '../models/song_note.dart';
import '../models/track.dart';

/// Lower-case letters, combining marks and digits only, so "Tum Hi Ho!"
/// equals "tum hi ho". Marks (\p{M}) are kept on purpose: in Hindi the vowel
/// signs are marks, and dropping them would make "तुम" and "तम" the same.
String normalizeForMatch(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{M}\p{N}]', unicode: true), '');

/// Whether [track] has this title, and this artist too when one is given.
/// Shared by notes and the song of the day, so both match a song the same way.
bool titleMatches(Track track, {required String title, String artist = ''}) {
  final wanted = normalizeForMatch(title);
  if (wanted.isEmpty || wanted != normalizeForMatch(track.title)) return false;

  final wantedArtist = normalizeForMatch(artist);
  return wantedArtist.isEmpty ||
      wantedArtist == normalizeForMatch(track.artist);
}

/// Whether [note] belongs to [track]. An id decides alone; otherwise the
/// title must match, and the artist too when the note names one.
bool songMatches(SongNote note, Track track) {
  final id = note.id;
  if (id != null) return id == track.id;
  return titleMatches(track, title: note.title, artist: note.artist);
}
