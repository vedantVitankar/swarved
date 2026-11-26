import 'track.dart';

/// One song remembered under "Recent searches": a song she played from the
/// search results, or added to a playlist from them.
///
/// It keeps just enough to show the row and to play the song again. A YouTube
/// song is rebuilt from what is kept here. A local song is found again in the
/// library by its [id], so a song that is no longer on this device simply
/// isn't offered.
class SearchHistoryEntry {
  const SearchHistoryEntry({
    required this.id,
    required this.isLocal,
    required this.title,
    required this.artist,
    this.durationSeconds = 0,
    this.videoId,
    this.artworkUrl,
  });

  /// [Track.id]: the file path for a local song, "yt:<videoId>" for YouTube.
  final String id;
  final bool isLocal;
  final String title;
  final String artist;
  final int durationSeconds;

  /// YouTube songs only.
  final String? videoId;
  final String? artworkUrl;

  /// What is kept of [track], or null for a song that can't be played again
  /// from here: one of his letter recordings, or a YouTube song with no id.
  static SearchHistoryEntry? fromTrack(Track track) {
    if (track.isLetterRecording) return null;
    final videoId = track.videoId;
    if (!track.isLocal && (videoId == null || videoId.isEmpty)) return null;
    return SearchHistoryEntry(
      id: track.id,
      isLocal: track.isLocal,
      title: track.title,
      artist: track.artist,
      durationSeconds: track.duration.inSeconds,
      videoId: track.isLocal ? null : videoId,
      artworkUrl: track.isLocal ? null : track.artworkUrl,
    );
  }

  /// The song to play, or null when it can't be found any more (a local song
  /// that is not in [library]).
  Track? toTrack(List<Track> library) {
    if (isLocal) {
      for (final track in library) {
        if (track.id == id) return track;
      }
      return null;
    }
    final video = videoId;
    if (video == null || video.isEmpty) return null;
    return Track.youtube(
      videoId: video,
      title: title,
      artist: artist,
      duration: Duration(seconds: durationSeconds),
      artworkUrl: artworkUrl,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'local': isLocal,
    'title': title,
    'artist': artist,
    'seconds': durationSeconds,
    if (videoId != null) 'videoId': videoId,
    if (artworkUrl != null) 'artworkUrl': artworkUrl,
  };

  /// Reads one saved entry. Returns null when it is not usable, so one bad
  /// entry never spoils the rest.
  static SearchHistoryEntry? tryParse(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final title = json['title'];
    final artist = json['artist'];
    final local = json['local'];
    if (id is! String || id.isEmpty) return null;
    if (title is! String || title.trim().isEmpty) return null;
    if (local is! bool) return null;

    final seconds = json['seconds'];
    final videoId = json['videoId'];
    final artworkUrl = json['artworkUrl'];
    if (!local && (videoId is! String || videoId.isEmpty)) return null;

    return SearchHistoryEntry(
      id: id,
      isLocal: local,
      title: title,
      artist: artist is String ? artist : '',
      durationSeconds: seconds is num && seconds > 0 ? seconds.round() : 0,
      videoId: videoId is String && videoId.isNotEmpty ? videoId : null,
      artworkUrl: artworkUrl is String && artworkUrl.isNotEmpty
          ? artworkUrl
          : null,
    );
  }
}
