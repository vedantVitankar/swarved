/// One handwritten note attached to a song. Built from the content file;
/// a bad entry is skipped rather than breaking the others.
class SongNote {
  /// "yt:<videoId>" for a YouTube song. When set, it alone decides the match.
  final String? id;

  /// For local songs: matched against the song's title (and artist, if given).
  final String title;
  final String artist;

  /// The small gold line above the note. Null uses the default dedication.
  final String? label;
  final String note;

  const SongNote({
    this.id,
    this.title = '',
    this.artist = '',
    this.label,
    required this.note,
  });

  static SongNote? tryParse(Object? json) {
    if (json is! Map) return null;
    final Map<dynamic, dynamic> map = json;

    String text(String key) {
      final value = map[key];
      return value is String ? value.trim() : '';
    }

    final note = text('note');
    final id = text('id');
    final title = text('title');
    if (note.isEmpty || (id.isEmpty && title.isEmpty)) return null;

    final label = text('label');
    return SongNote(
      id: id.isEmpty ? null : id,
      title: title,
      artist: text('artist'),
      label: label.isEmpty ? null : label,
      note: note,
    );
  }
}
