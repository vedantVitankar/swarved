import 'package:flutter/material.dart';
import '../models/track.dart';
import '../theme/colors.dart';
import '../theme/shape.dart';
import '../theme/typography.dart';
import 'song_row_end.dart';
import 'track_artwork.dart';
import 'track_heart.dart';

/// One song in a folder: rounded art, title, artist, length.
/// The song that is playing gets a rose title on a soft velvet row. The end
/// of the row has download (YouTube songs), length and the heart. Holding the
/// row likes the song, or takes it out of Liked songs.
class TrackTile extends StatelessWidget {
  final Track track;
  final bool isActive;

  /// Null shows the row without making it tappable.
  final VoidCallback? onTap;

  const TrackTile({
    super.key,
    required this.track,
    required this.onTap,
    this.isActive = false,
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
          onLongPress: () => TrackHeart.quickToggle(context, track),
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
                SongRowEnd(track: track, durationLabel: track.durationLabel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
