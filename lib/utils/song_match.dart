import '../models/song_note.dart';
import '../models/track.dart';

/// Lower-case letters, combining marks and digits only, so "Tum Hi Ho!"
/// equals "tum hi ho". Marks (\p{M}) are kept on purpose: in Hindi the vowel
/// signs are marks, and dropping them would make "तुम" and "तम" the same.
String normalizeForMatch(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{M}\p{N}]', unicode: true), '');

/// Whether [note] belongs to [track]. An id decides alone; otherwise the
/// title must match, and the artist too when the note names one.
bool songMatches(SongNote note, Track track) {
  final id = note.id;
  if (id != null) return id == track.id;

  final title = normalizeForMatch(note.title);
  if (title.isEmpty || title != normalizeForMatch(track.title)) return false;

  final artist = normalizeForMatch(note.artist);
  return artist.isEmpty || artist == normalizeForMatch(track.artist);
}
