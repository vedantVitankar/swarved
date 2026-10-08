import 'package:flutter/material.dart';
import '../content/labels.dart';
import '../models/track.dart';
import '../theme/colors.dart';
import '../theme/shape.dart';
import '../theme/swar_glyphs.dart';
import '../theme/typography.dart';
import 'compact_icon_button.dart';
import 'track_artwork.dart';

/// The song he picked for her today: a gold label, the song with a rose
/// play button, and his handwritten note underneath when there is one.
/// Plain and stateless; the screen decides what a tap does.
class SongOfTheDayCard extends StatelessWidget {
  final Track track;
  final String label;
  final String? note;

  /// Whether this very song is playing right now, so the button shows pause.
  final bool isPlaying;
  final VoidCallback onTap;

  const SongOfTheDayCard({
    super.key,
    required this.track,
    required this.label,
    required this.onTap,
    this.note,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final note = this.note;

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShape.card),
        side: const BorderSide(color: AppColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppType.goldLabel),
              const SizedBox(height: 10),
              Row(
                children: [
                  TrackArtwork(
                    bytes: track.artworkBytes,
                    url: track.artworkUrl,
                    size: 56,
                    iconSize: 24,
                    radius: AppShape.thumbnail,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          style: AppType.trackTitle,
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
                  const SizedBox(width: 8),
                  CompactIconButton(
                    icon: isPlaying ? SwarGlyph.pause : SwarGlyph.play,
                    tooltip: isPlaying ? Labels.pause : Labels.play,
                    boxSize: 44,
                    iconSize: 22,
                    color: AppColors.onAccent,
                    background: AppColors.accent,
                    onPressed: onTap,
                  ),
                ],
              ),
              if (note != null) ...[
                const SizedBox(height: 10),
                // As on every note card, the words are cream; only the
                // label is gold.
                Text(
                  note,
                  style: AppType.note.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
