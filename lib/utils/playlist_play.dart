import 'playlist_resolve.dart';

/// Where line [lineIndex] of a playlist sits among the songs that can be
/// played now, which is the start position to give the player. Null when
/// the line does not exist, or its song is not on this device.
int? playableIndexOf(List<ResolvedItem> resolved, int lineIndex) {
  if (lineIndex < 0 || lineIndex >= resolved.length) return null;
  if (!resolved[lineIndex].isAvailable) return null;
  var before = 0;
  for (var i = 0; i < lineIndex; i++) {
    if (resolved[i].isAvailable) before++;
  }
  return before;
}
