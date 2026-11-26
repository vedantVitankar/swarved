import '../models/search_history_entry.dart';

/// How many songs "Recent searches" keeps.
const int kSearchHistoryLimit = 20;

/// [entry] goes to the top. If the song was already there it moves up
/// instead of appearing twice. Only the newest [limit] are kept.
List<SearchHistoryEntry> withRecorded(
  List<SearchHistoryEntry> current,
  SearchHistoryEntry entry, {
  int limit = kSearchHistoryLimit,
}) {
  return [
    entry,
    for (final old in current)
      if (old.id != entry.id) old,
  ].take(limit).toList();
}

/// [current] without the song named [id].
List<SearchHistoryEntry> withoutEntry(
  List<SearchHistoryEntry> current,
  String id,
) {
  return [
    for (final entry in current)
      if (entry.id != id) entry,
  ];
}
