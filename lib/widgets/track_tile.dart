import 'package:flutter/material.dart';
import '../models/track.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'track_artwork.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final bool isActive;
  final VoidCallback onTap;

  const TrackTile({
    super.key,
    required this.track,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: const Border(
            bottom: BorderSide(color: AppColors.hairline, width: 1),
          ),
          color: isActive ? AppColors.surfaceRaised : Colors.transparent,
        ),
        child: Row(
          children: [
            TrackArtwork(bytes: track.artworkBytes),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: AppType.titleMedium.copyWith(
                      color: isActive
                          ? AppColors.accent
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist,
                    style: AppType.bodyMuted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(track.durationLabel, style: AppType.readout),
          ],
        ),
      ),
    );
  }
}
