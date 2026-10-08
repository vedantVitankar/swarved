import 'dart:convert';
import 'song_note.dart';
import 'song_of_the_day.dart';
import 'track.dart';
import '../utils/song_match.dart';

/// Everything he has written for her, as one immutable bundle.
/// Later phases add more to this (playlists, voice).
class ContentPack {
  final List<SongNote> notes;

  /// The song he picked for today, or null when he hasn't picked one.
  final SongOfTheDay? songOfTheDay;

  const ContentPack({this.notes = const [], this.songOfTheDay});

  static const empty = ContentPack();

  /// Throws [FormatException] when [source] isn't a JSON object.
  /// Individual bad entries are skipped, and a bad song of the day is
  /// treated as none.
  factory ContentPack.parse(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Content must be a JSON object');
    }
    final raw = decoded['notes'];
    final notes = <SongNote>[];
    if (raw is List) {
      for (final item in raw) {
        final note = SongNote.tryParse(item);
        if (note != null) notes.add(note);
      }
    }
    return ContentPack(
      notes: List.unmodifiable(notes),
      songOfTheDay: SongOfTheDay.tryParse(decoded['songOfTheDay']),
    );
  }

  /// The first note that belongs to [track], or null.
  SongNote? noteFor(Track track) {
    for (final note in notes) {
      if (songMatches(note, track)) return note;
    }
    return null;
  }
}
