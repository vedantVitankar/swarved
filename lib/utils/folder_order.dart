import '../models/track.dart';

/// Folders A to Z, ignoring upper and lower case. Two names that differ
/// only by case fall back to their exact spelling, so the order never
/// changes between runs.
List<MapEntry<String, List<Track>>> sortedFolders(
  Map<String, List<Track>> byFolder,
) {
  final entries = byFolder.entries.toList();
  entries.sort((a, b) {
    final byName = a.key.toLowerCase().compareTo(b.key.toLowerCase());
    return byName != 0 ? byName : a.key.compareTo(b.key);
  });
  return entries;
}
