import 'package:flutter/material.dart';
import '../../models/track.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../widgets/track_artwork.dart';

class ContinueCard extends StatelessWidget {
  final Track track;
  final VoidCallback onPlay;
  const ContinueCard({super.key, required this.track, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          TrackArtwork(bytes: track.artworkBytes, size: 56, iconSize: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(track.title,
                    style: AppType.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${track.artist} · ${track.durationLabel}',
                    style: AppType.bodyMuted),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_fill,
                color: AppColors.accent, size: 34),
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}
