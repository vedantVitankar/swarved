import '../models/playlist.dart';
import '../models/playlist_item.dart';
import '../models/track.dart';
import '../models/youtube_result.dart';
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

/// Every YouTube song of [playlist], in order, as what saving needs. Local
/// songs are already files, so they are left out.
List<YoutubeResult> youtubeSongsOf(Playlist playlist) => [
      for (final item in playlist.items)
        if (item.toYoutubeResult() != null) item.toYoutubeResult()!,
    ];

/// One picture for a playlist's cover: a local song's own artwork, or a
/// YouTube song's thumbnail.
class PlaylistCover {
  const PlaylistCover({this.bytes, this.url});

  final List<int>? bytes;
  final String? url;
}

/// The pictures of the first [count] songs of [playlist], in order, for its
/// cover. A song with no picture is left out. A local song's picture is
/// found in [library] by its key; a song not in the library has none.
List<PlaylistCover> playlistCovers(
  Playlist playlist,
  Iterable<Track> library, {
  int count = 4,
}) {
  final head = playlist.items.take(count).toList();

  final wanted = {
    for (final item in head)
      if (item.isLocal) item.key,
  };
  final found = <String, Track>{};
  if (wanted.isNotEmpty) {
    for (final track in library) {
      if (!track.isLocal) continue;
      final key = track.playlistKey;
      if (wanted.contains(key)) found.putIfAbsent(key, () => track);
      if (found.length == wanted.length) break;
    }
  }

  final covers = <PlaylistCover>[];
  for (final item in head) {
    if (item.isYoutube) {
      final url = item.artworkUrl;
      if (url != null) covers.add(PlaylistCover(url: url));
    } else if (item.isLocal) {
      final bytes = found[item.key]?.artworkBytes;
      if (bytes != null) covers.add(PlaylistCover(bytes: bytes));
    }
  }
  return covers;
}
