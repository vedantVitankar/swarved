import 'package:flutter/material.dart';
import '../../content/words.dart';
import '../../models/track.dart';
import '../../widgets/track_tile.dart';
import 'search_section_header.dart';

/// The songs already in the library that match the search.
/// Shows nothing at all when none match.
class LocalResultsSection extends StatelessWidget {
  final List<Track> matches;

  /// The id of the song playing now, so its row can glow rose.
  final String? activeId;

  /// Called with the index of the tapped match.
  final ValueChanged<int> onPlay;

  const LocalResultsSection({
    super.key,
    required this.matches,
    required this.activeId,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SearchSectionHeader(title: Words.searchLocalHeader),
        for (var i = 0; i < matches.length; i++)
          TrackTile(
            track: matches[i],
            isActive: activeId == matches[i].id,
            onTap: () => onPlay(i),
          ),
      ],
    );
  }
}
