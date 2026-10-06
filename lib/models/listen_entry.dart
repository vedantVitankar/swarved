class ListenEntry {
  /// The track's id: a file path for local songs, "yt:<videoId>" for
  /// YouTube. The name and JSON key stay "trackPath" so saved logs load.
  final String trackPath;
  final String title;
  final String artist;
  final DateTime playedAt;
  final Duration listened;

  ListenEntry({
    required this.trackPath,
    required this.title,
    required this.artist,
    required this.playedAt,
    required this.listened,
  });

  Map<String, dynamic> toJson() => {
        'trackPath': trackPath,
        'title': title,
        'artist': artist,
        'playedAt': playedAt.toIso8601String(),
        'listenedSeconds': listened.inSeconds,
      };

  factory ListenEntry.fromJson(Map<String, dynamic> json) => ListenEntry(
        trackPath: json['trackPath'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String,
        playedAt: DateTime.parse(json['playedAt'] as String),
        listened: Duration(seconds: json['listenedSeconds'] as int),
      );
}
