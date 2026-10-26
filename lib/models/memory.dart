import 'song_of_the_day.dart';

/// One moment on memory lane: a date, a title, a few words, and usually a
/// photo, like a note with a picture. Built from the content; a bad entry is
/// skipped rather than breaking the others.
class Memory {
  /// Photos bundled inside the app live under assets/.
  static const _assetPrefix = 'assets/';

  /// Photos he uploads are named by the server: sixteen hex digits and an
  /// extension. Anything else is not a photo the app may fetch.
  static final _serverPhoto = RegExp(r'^[a-f0-9]{16}\.(jpg|png|webp)$');

  final DateTime date;

  /// His words about the moment.
  final String caption;

  /// A short heading, or empty when he gave none.
  final String title;

  /// Either an asset path such as "assets/memories/first-date.jpg", or the
  /// name of a photo on the server, or null.
  final String? image;

  /// A song from that day, played from the photo note, or null.
  final SongOfTheDay? song;

  /// False when he keeps this one for memory lane only, out of the Home
  /// right-hand section.
  final bool inPanel;

  const Memory({
    required this.date,
    required this.caption,
    this.title = '',
    this.image,
    this.song,
    this.inPanel = true,
  });

  /// Whether [name] is a photo kept on the server.
  static bool isServerPhoto(String name) => _serverPhoto.hasMatch(name);

  /// True when the photo has to be fetched from the server.
  bool get hasServerPhoto => image != null && isServerPhoto(image!);

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
    final usable = image.startsWith(_assetPrefix) || isServerPhoto(image);
    return Memory(
      date: date,
      caption: caption,
      title: text('title'),
      image: usable ? image : null,
      song: SongOfTheDay.tryParse(map['song']),
      inPanel: map['hideFromPanel'] != true,
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
