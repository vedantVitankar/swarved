import '../models/track.dart';

/// Folder names, the one listened to most recently first. Folders never
/// listened to follow, the biggest first, then by name, so the order is the
/// same on every run.
///
/// [recentTrackIds] are track ids (a file path for a local song), newest
/// first, as the listening log keeps them. Ids that are not in any folder,
/// such as YouTube songs, are skipped.
List<String> foldersByRecency(
  Map<String, List<Track>> byFolder,
  Iterable<String> recentTrackIds,
) {
  final folderOf = <String, String>{};
  for (final entry in byFolder.entries) {
    for (final track in entry.value) {
      folderOf[track.id] = entry.key;
    }
  }

  final seen = <String>{};
  final ordered = <String>[];
  for (final id in recentTrackIds) {
    final folder = folderOf[id];
    if (folder != null && seen.add(folder)) ordered.add(folder);
  }

  final rest = [
    for (final entry in byFolder.entries)
      if (!seen.contains(entry.key)) entry,
  ]..sort((a, b) {
      final bySize = b.value.length.compareTo(a.value.length);
      return bySize != 0 ? bySize : a.key.compareTo(b.key);
    });

  return [...ordered, for (final entry in rest) entry.key];
}
