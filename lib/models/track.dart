import '../utils/duration_format.dart';
import 'track_source.dart';

class Track {
  /// Local songs only. Empty for YouTube tracks: use [id] for identity.
  final String filePath;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String folder;
  final List<int>? artworkBytes;

  final TrackSource source;

  /// YouTube tracks only.
  final String? videoId;
  final String? artworkUrl;

  Track({
    required this.filePath,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.folder,
    this.artworkBytes,
    this.source = TrackSource.local,
    this.videoId,
    this.artworkUrl,
  }) : assert(
          source == TrackSource.local ||
              (videoId != null && videoId.isNotEmpty),
          'A YouTube track needs a videoId',
        );

  Track.youtube({
    required String videoId,
    required this.title,
    required this.artist,
    required this.duration,
    this.artworkUrl,
  })  : assert(videoId.isNotEmpty),
        filePath = '',
        album = '',
        folder = '',
        artworkBytes = null,
        source = TrackSource.youtube,
        videoId = videoId;

  bool get isLocal => source == TrackSource.local;

  /// Stable identity: the file path for local songs, "yt:<videoId>" for
  /// YouTube. Use this, not filePath, wherever a song must be recognised.
  String get id => isLocal ? filePath : 'yt:$videoId';

  String get durationLabel => formatDuration(duration);
}
