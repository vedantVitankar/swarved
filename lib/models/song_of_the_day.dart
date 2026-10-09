import 'track.dart';
import '../utils/song_match.dart';

/// The one song he picked for her today, with an optional note.
/// Built from the content file; a bad entry means no song of the day
/// rather than a broken app.
///
/// Two kinds:
///  - a song from her library: just a [title] (and an [artist] if two songs
///    share a title). It is looked up in the library when shown.
///  - a YouTube song: an [id] ("yt:<videoId>") plus the [title] and [artist]
///    to show, because there is no library to look them up in.
class SongOfTheDay {
  static const _youtubePrefix = 'yt:';

  /// "yt:<videoId>" for a YouTube song, null for a library song.
  final String? id;
  final String title;
  final String artist;

  /// YouTube songs only. Both are optional; the card copes without them.
  final Duration? duration;
  final String? thumbnailUrl;

  /// The small gold line above the card. Null uses the default.
  final String? label;

  /// A handwritten line shown on the card. Null shows none.
  final String? note;

  const SongOfTheDay({
    this.id,
    required this.title,
    this.artist = '',
    this.duration,
    this.thumbnailUrl,
    this.label,
    this.note,
  });

  static SongOfTheDay? tryParse(Object? json) {
    if (json is! Map) return null;
    final Map<dynamic, dynamic> map = json;

    String text(String key) {
      final value = map[key];
      return value is String ? value.trim() : '';
    }

    final title = text('title');
    if (title.isEmpty) return null;

    final id = text('id');
    final hasValidId =
        id.length > _youtubePrefix.length && id.startsWith(_youtubePrefix);
    if (id.isNotEmpty && !hasValidId) return null;

    final seconds = map['durationSeconds'];
    final thumbnail = text('thumbnailUrl');
    final label = text('label');
    final note = text('note');

    return SongOfTheDay(
      id: id.isEmpty ? null : id,
      title: title,
      artist: text('artist'),
      duration: seconds is num && seconds > 0
          ? Duration(seconds: seconds.round())
          : null,
      thumbnailUrl: thumbnail.isEmpty ? null : thumbnail,
      label: label.isEmpty ? null : label,
      note: note.isEmpty ? null : note,
    );
  }

  /// The song as a [Track] that can be played, or null when it is a library
  /// song that isn't in [library] (not scanned yet, or since removed).
  Track? resolve(List<Track> library) {
    final id = this.id;
    if (id != null) {
      return Track.youtube(
        videoId: id.substring(_youtubePrefix.length),
        title: title,
        artist: artist,
        duration: duration ?? Duration.zero,
        artworkUrl: thumbnailUrl,
      );
    }

    for (final track in library) {
      if (titleMatches(track, title: title, artist: artist)) return track;
    }
    return null;
  }
}
