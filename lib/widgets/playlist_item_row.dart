import 'package:flutter/material.dart';
import '../models/playlist_item.dart';
import '../models/track.dart';
import '../theme/colors.dart';
import '../theme/shape.dart';
import '../theme/typography.dart';
import '../utils/duration_format.dart';
import 'track_artwork.dart';

/// One line of a playlist: art, title, artist, length. It is drawn from the
/// details saved with the song, so it shows even when the song is not on
/// this device. [track] is the playable song when there is one, and is only
/// used for its artwork. A line with no song is dimmed.
class PlaylistItemRow extends StatelessWidget {
  final PlaylistItem item;
  final Track? track;
  final bool isActive;
  final VoidCallback onTap;

  const PlaylistItemRow({
    super.key,
    required this.item,
    required this.track,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final available = track != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: isActive ? AppColors.surfaceRaised : Colors.transparent,
        borderRadius: BorderRadius.circular(AppShape.tile),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Opacity(
            opacity: available ? 1 : 0.45,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Row(
                children: [
                  TrackArtwork(
                    bytes: track?.artworkBytes,
                    url: item.artworkUrl ?? track?.artworkUrl,
                    radius: AppShape.thumbnail,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          style: AppType.body.copyWith(
                            color: isActive
                                ? AppColors.accent
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.artist,
                          style: AppType.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(formatDuration(item.duration), style: AppType.readout),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
