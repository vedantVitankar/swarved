import 'playlist_service.dart';
import 'search_history_service.dart';

/// Notices songs added to a playlist and tells [SearchHistoryService], which
/// records the ones that came from the search results. It only listens, so
/// the playlists are never touched.
class SearchHistoryWatcher {
  SearchHistoryWatcher({required this.history, required this.playlists});

  final SearchHistoryService history;
  final PlaylistService playlists;

  /// Every song in every playlist, as "playlist, song" pairs, so a song that
  /// is already in one playlist still counts when it is added to another.
  Set<(String, String)> _known = const {};
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    _known = _pairs();
    playlists.addListener(_check);
  }

  void dispose() {
    playlists.removeListener(_check);
    _started = false;
  }

  Set<(String, String)> _pairs() => {
    for (final playlist in playlists.playlists)
      for (final item in playlist.items) (playlist.id, item.key),
  };

  void _check() {
    final now = _pairs();
    final added = now.difference(_known);
    _known = now;
    if (added.isNotEmpty) {
      history.recordAdded({for (final (_, key) in added) key});
    }
  }
}
