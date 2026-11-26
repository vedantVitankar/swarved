import 'package:flutter/material.dart';

import '../../content/labels.dart';
import '../../content/words.dart';
import '../../models/track.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/swar_glyphs.dart';
import '../../theme/typography.dart';
import '../../widgets/compact_icon_button.dart';
import '../../widgets/track_artwork.dart';

/// What the Search tab shows while the bar is empty and there is something
/// to remember: the songs she played or added to a playlist from the search,
/// newest first. Each row has an × that removes just that song, and "Clear
/// all" empties the list.
class SearchHistorySection extends StatelessWidget {
  /// Newest first. The songs that can still be played.
  final List<Track> tracks;

  /// The id of the song playing now, so its row can glow rose.
  final String? activeId;

  final ValueChanged<Track> onPlay;
  final ValueChanged<Track> onRemove;
  final VoidCallback onClearAll;

  const SearchHistorySection({
    super.key,
    required this.tracks,
    required this.activeId,
    required this.onPlay,
    required this.onRemove,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  Words.searchRecentHeader,
                  style: AppType.sectionLabel,
                ),
              ),
              TextButton(
                onPressed: onClearAll,
                child: Text(Labels.clearAllRecent, style: AppType.goldLabel),
              ),
            ],
          ),
        ),
        for (final track in tracks)
          _HistoryRow(
            key: ValueKey(track.id),
            track: track,
            isActive: activeId == track.id,
            onTap: () => onPlay(track),
            onRemove: () => onRemove(track),
          ),
      ],
    );
  }
}

/// One remembered song: the same look as a result row, with an × at the end
/// instead of the download, length and heart.
class _HistoryRow extends StatelessWidget {
  final Track track;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _HistoryRow({
    super.key,
    required this.track,
    required this.isActive,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: isActive ? AppColors.surfaceRaised : Colors.transparent,
        borderRadius: BorderRadius.circular(AppShape.tile),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              children: [
                TrackArtwork(
                  bytes: track.artworkBytes,
                  url: track.artworkUrl,
                  radius: AppShape.thumbnail,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        track.title,
                        style: AppType.body.copyWith(
                          color: isActive
                              ? AppColors.accent
                              : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        track.artist,
                        style: AppType.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                CompactIconButton(
                  icon: SwarGlyph.close,
                  iconSize: 18,
                  boxSize: 36,
                  color: AppColors.textSecondary,
                  tooltip: Labels.removeFromRecent,
                  onPressed: onRemove,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
