import '../utils/duration_format.dart';

class Track {
  final String filePath;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String folder;
  final List<int>? artworkBytes;

  Track({
    required this.filePath,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.folder,
    this.artworkBytes,
  });

  String get durationLabel => formatDuration(duration);
}
