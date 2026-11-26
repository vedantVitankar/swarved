import 'package:flutter/foundation.dart';

import '../models/search_history_entry.dart';
import '../models/track.dart';
import '../utils/search_history_list.dart';
import '../utils/track_key.dart';
import 'search_history_store.dart';

/// "Recent searches": the songs she played from the search results, or added
/// to a playlist from them, newest first. Every change is applied at once,
/// tells listeners, and is saved in the background, one save after another.
///
/// Nothing here touches searching, playing or the playlists. The Search tab
/// tells this what was played, and [SearchHistoryWatcher] tells it what was
/// added to a playlist.
class SearchHistoryService extends ChangeNotifier {
  SearchHistoryService({
    required SearchHistoryStore store,
    int limit = kSearchHistoryLimit,
  }) : _store = store,
       _limit = limit;

  final SearchHistoryStore _store;
  final int _limit;

  List<SearchHistoryEntry> _entries = const [];
  List<Track> _shown = const [];
  Future<void> _writing = Future.value();
  bool _disposed = false;

  /// Newest first.
  List<SearchHistoryEntry> get entries => _entries;

  /// Completes when everything changed so far has been saved. For tests.
  Future<void> get saved => _writing;

  /// Reads the file. Never throws. Anything recorded before it finished
  /// stays on top.
  Future<void> load() async {
    List<SearchHistoryEntry> found;
    try {
      found = await _store.read();
    } catch (error) {
      debugPrint('Recent searches could not be read: $error');
      return;
    }
    final mine = {for (final entry in _entries) entry.id};
    _entries = [
      ..._entries,
      for (final entry in found)
        if (!mine.contains(entry.id)) entry,
    ].take(_limit).toList();
    _changed(save: false);
  }

  /// The songs the Search tab is showing right now. Only these can be
  /// recorded as "added to a playlist", so a song added somewhere else, or
  /// pulled in by a sync, never lands here. Does not notify: the screen calls
  /// this while it builds.
  void noteShown(Iterable<Track> tracks) => _shown = List.of(tracks);

  /// A song was played from the search results (or from this list).
  void recordPlayed(Track track) {
    final entry = SearchHistoryEntry.fromTrack(track);
    if (entry == null) return;
    _entries = withRecorded(_entries, entry, limit: _limit);
    _changed();
  }

  /// These playlist keys were just added to a playlist. The ones that are
  /// shown in the search results are recorded.
  void recordAdded(Set<String> playlistKeys) {
    if (playlistKeys.isEmpty || _shown.isEmpty) return;
    for (final track in _shown) {
      if (playlistKeys.contains(track.playlistKey)) recordPlayed(track);
    }
  }

  /// The × on one row.
  void remove(String id) {
    final next = withoutEntry(_entries, id);
    if (next.length == _entries.length) return;
    _entries = next;
    _changed();
  }

  /// "Clear all".
  void clearAll() {
    if (_entries.isEmpty) return;
    _entries = const [];
    _changed();
  }

  void _changed({bool save = true}) {
    if (!_disposed) notifyListeners();
    if (!save) return;
    final snapshot = List.of(_entries);
    _writing = _writing.then((_) => _store.write(snapshot)).catchError((
      Object error,
    ) {
      debugPrint('Recent searches could not be saved: $error');
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
