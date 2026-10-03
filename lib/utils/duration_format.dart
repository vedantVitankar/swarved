/// Formats a Duration as mm:ss. The one place this logic lives —
/// nothing else should hand-roll its own duration string.
String formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
