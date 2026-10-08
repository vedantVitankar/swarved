import '../models/track.dart';
import 'search_query.dart';

/// How many of the library's matches the Search tab shows at most.
const int kLocalResultLimit = 20;

/// The songs in [tracks] that match [query]. Every word typed has to appear
/// somewhere in the title, artist, album or folder name, in any letter case.
/// Songs whose title matches come first; each group keeps the library order.
List<Track> searchLocal(
  List<Track> tracks,
  String query, {
  int limit = kLocalResultLimit,
}) {
  final words = normalizeQuery(query)
      .toLowerCase()
      .split(' ')
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return const [];

  final titleMatches = <Track>[];
  final otherMatches = <Track>[];

  for (final track in tracks) {
    final title = track.title.toLowerCase();
    if (words.every((word) => title.contains(word))) {
      titleMatches.add(track);
      continue;
    }
    final text =
        '$title ${track.artist} ${track.album} ${track.folder}'.toLowerCase();
    if (words.every((word) => text.contains(word))) {
      otherMatches.add(track);
    }
  }

  return [...titleMatches, ...otherMatches].take(limit).toList();
}
