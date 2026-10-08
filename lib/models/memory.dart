/// One moment on memory lane: a date, a few words, and usually a photo.
/// Built from the content file; a bad entry is skipped rather than
/// breaking the others.
class Memory {
  /// Photos must live inside the app, under assets/.
  static const _assetPrefix = 'assets/';

  final DateTime date;
  final String caption;

  /// An asset path such as "assets/memories/first-date.jpg", or null.
  final String? image;

  const Memory({required this.date, required this.caption, this.image});

  static Memory? tryParse(Object? json) {
    if (json is! Map) return null;
    final Map<dynamic, dynamic> map = json;

    String text(String key) {
      final value = map[key];
      return value is String ? value.trim() : '';
    }

    final date = parseDate(text('date'));
    final caption = text('caption');
    if (date == null || caption.isEmpty) return null;

    final image = text('image');
    return Memory(
      date: date,
      caption: caption,
      image: image.startsWith(_assetPrefix) ? image : null,
    );
  }

  /// "2025-02-14" as a date, or null. Dates that don't exist, like
  /// "2025-02-30", are refused instead of rolling over into March.
  static DateTime? parseDate(String text) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
    if (match == null) return null;

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    final exists = date.year == year && date.month == month && date.day == day;
    return exists ? date : null;
  }

  /// [memories] from oldest to newest. Two on the same day keep the order
  /// they were written in.
  static List<Memory> inOrder(Iterable<Memory> memories) {
    final indexed = memories.toList().asMap().entries.toList()
      ..sort((a, b) {
        final byDate = a.value.date.compareTo(b.value.date);
        return byDate != 0 ? byDate : a.key.compareTo(b.key);
      });
    return List.unmodifiable([for (final entry in indexed) entry.value]);
  }
}
