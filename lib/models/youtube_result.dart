import 'track.dart';

/// One song the server found on YouTube Music, as it described it.
/// Searching only ever produces these; nothing is downloaded.
class YoutubeResult {
  const YoutubeResult({
    required this.id,
    required this.title,
    required this.artist,
    this.duration,
    this.thumbnailUrl,
  });

  final String id;
  final String title;

  /// Empty when YouTube named no artist.
  final String artist;

  /// Null when YouTube gave no length.
  final Duration? duration;
  final String? thumbnailUrl;

  /// Reads one entry of the server's "results" list. Returns null when the
  /// entry has no usable id or title, so one bad entry can't spoil the rest.
  static YoutubeResult? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;

    final id = json['id'];
    final title = json['title'];
    if (id is! String || id.isEmpty) return null;
    if (title is! String || title.trim().isEmpty) return null;

    final artist = json['artist'];
    final seconds = json['durationSeconds'];
    final thumbnail = json['thumbnailUrl'];

    return YoutubeResult(
      id: id,
      title: title.trim(),
      artist: artist is String ? artist.trim() : '',
      duration: seconds is num && seconds > 0
          ? Duration(seconds: seconds.round())
          : null,
      thumbnailUrl:
          thumbnail is String && thumbnail.isNotEmpty ? thumbnail : null,
    );
  }

  /// Reads a whole search response, {"results": [...]}. Throws a
  /// FormatException when the shape is wrong. Unusable entries and repeated
  /// ids are skipped.
  static List<YoutubeResult> parseList(Object? body) {
    if (body is! Map<String, dynamic>) {
      throw const FormatException('search response is not an object');
    }
    final raw = body['results'];
    if (raw is! List) {
      throw const FormatException('search response has no results list');
    }

    final seen = <String>{};
    final results = <YoutubeResult>[];
    for (final item in raw) {
      final result = tryParse(item);
      if (result != null && seen.add(result.id)) results.add(result);
    }
    return results;
  }

  /// The same song as a [Track], so it can sit in the app's queue and lists.
  Track toTrack() => Track.youtube(
        videoId: id,
        title: title,
        artist: artist,
        duration: duration ?? Duration.zero,
        artworkUrl: thumbnailUrl,
      );
}
