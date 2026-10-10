import '../models/playlist.dart';
import '../models/playlist_item.dart';
import '../models/track.dart';
import 'track_key.dart';

/// One line of a playlist, and the song to play for it. [track] is null for
/// a local song that is not in this device's library: the line stays in the
/// playlist, dimmed, and is skipped when playing.
class ResolvedItem {
  const ResolvedItem(this.item, this.track);

  final PlaylistItem item;
  final Track? track;

  bool get isAvailable => track != null;
}

/// Matches every line of [playlist] to a playable song. A YouTube line plays
/// from the details it was saved with. A local line is looked for in
/// [library] by its key, and the first match wins.
List<ResolvedItem> resolvePlaylist(
  Playlist playlist,
  Iterable<Track> library,
) {
  final local = <String, Track>{};
  if (playlist.items.any((item) => item.isLocal)) {
    for (final track in library) {
      if (track.isLocal) local.putIfAbsent(track.playlistKey, () => track);
    }
  }
  return [
    for (final item in playlist.items)
      ResolvedItem(item, item.isLocal ? local[item.key] : item.toYoutubeTrack()),
  ];
}

/// Just the songs that can be played now, in the playlist's order.
List<Track> playableTracks(List<ResolvedItem> resolved) => [
      for (final line in resolved)
        if (line.track != null) line.track!,
    ];
