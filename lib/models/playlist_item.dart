import '../utils/track_key.dart';
import 'track.dart';

/// One song in a playlist: its key, and a snapshot of how it looked when it
/// was added, so a playlist can be drawn without the song being on this
/// device, and without the network.
class PlaylistItem {
  const PlaylistItem({
    required this.key,
    required this.title,
    required this.artist,
    required this.duration,
    required this.addedAt,
    this.artworkUrl,
  });

  /// "yt:<videoId>" or "local:<hash>", see [TrackPlaylistKey].
  final String key;
  final String title;
  final String artist;
  final Duration duration;

  /// YouTube songs only. A local song's artwork lives in its file.
  final String? artworkUrl;
  final DateTime addedAt;

  bool get isLocal => key.startsWith(localKeyPrefix);
  bool get isYoutube => key.startsWith(youtubeKeyPrefix);

  factory PlaylistItem.fromTrack(Track track, {required DateTime addedAt}) {
    return PlaylistItem(
      key: track.playlistKey,
      title: track.title,
      artist: track.artist,
      duration: track.duration,
      artworkUrl: track.isLocal ? null : track.artworkUrl,
      addedAt: addedAt,
    );
  }

  /// The song as something the player can play, for a YouTube item. Null for
  /// a local item, which has to be found in the library, and for a key that
  /// is neither.
  Track? toYoutubeTrack() {
    if (!isYoutube) return null;
    final videoId = key.substring(youtubeKeyPrefix.length);
    if (videoId.isEmpty) return null;
    return Track.youtube(
      videoId: videoId,
      title: title,
      artist: artist,
      duration: duration,
      artworkUrl: artworkUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'title': title,
        'artist': artist,
        'durationSeconds': duration.inSeconds,
        if (artworkUrl != null) 'artworkUrl': artworkUrl,
        'addedAt': addedAt.toUtc().toIso8601String(),
      };

  /// Null when [json] has no usable key, so one bad entry never spoils the
  /// rest of a playlist.
  static PlaylistItem? tryParse(Object? json) {
    if (json is! Map) return null;
    final key = json['key'];
    if (key is! String) return null;
    if (!key.startsWith(localKeyPrefix) && !key.startsWith(youtubeKeyPrefix)) {
      return null;
    }
    if (key == localKeyPrefix || key == youtubeKeyPrefix) return null;

    final title = json['title'];
    final artist = json['artist'];
    final seconds = json['durationSeconds'];
    final art = json['artworkUrl'];
    final added = json['addedAt'];

    return PlaylistItem(
      key: key,
      title: title is String ? title : '',
      artist: artist is String ? artist : '',
      duration: seconds is num && seconds > 0
          ? Duration(seconds: seconds.round())
          : Duration.zero,
      artworkUrl: art is String && art.isNotEmpty ? art : null,
      addedAt: added is String ? DateTime.tryParse(added) ?? _epoch : _epoch,
    );
  }

  static final DateTime _epoch = DateTime.utc(1970);
}
