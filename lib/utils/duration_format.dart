/// Formats a Duration as mm:ss. The one place this logic lives —
/// nothing else should hand-roll its own duration string.
String formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// A listening time in words: "less than a minute", "42 min", "5 h",
/// "5 h 30 min". For totals, where mm:ss would be too exact.
String listenedLabel(Duration d) {
  final totalMinutes = d.inMinutes;
  if (totalMinutes < 1) return 'less than a minute';
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours == 0) return '$minutes min';
  return minutes == 0 ? '$hours h' : '$hours h $minutes min';
}
