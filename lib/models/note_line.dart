/// One short note for a place in the app: the words, and optionally the
/// small gold label above them. Built from the content file.
class NoteLine {
  final String? label;
  final String note;

  const NoteLine({this.label, required this.note});

  /// Accepts a bare string ("I miss you") or an object with "note" and an
  /// optional "label". Anything else, or an empty note, gives null so one
  /// bad entry can't spoil the rest.
  static NoteLine? tryParse(Object? json) {
    if (json is String) {
      final text = json.trim();
      return text.isEmpty ? null : NoteLine(note: text);
    }
    if (json is! Map) return null;

    final note = json['note'];
    if (note is! String || note.trim().isEmpty) return null;

    final label = json['label'];
    final trimmedLabel = label is String ? label.trim() : '';
    return NoteLine(
      label: trimmedLabel.isEmpty ? null : trimmedLabel,
      note: note.trim(),
    );
  }

  // Equal by words, so a screen listening for "its note changed" doesn't
  // rebuild when the same note is looked up again.
  @override
  bool operator ==(Object other) =>
      other is NoteLine && other.label == label && other.note == note;

  @override
  int get hashCode => Object.hash(label, note);
}
