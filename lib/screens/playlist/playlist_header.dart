import 'package:flutter/material.dart';
import '../../content/labels.dart';
import '../../content/words.dart';
import '../../models/playlist.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/swar_glyphs.dart';
import '../../theme/typography.dart';
import '../../widgets/playlist_art.dart';
import '../../widgets/swar_icon.dart';
import '../../widgets/swar_outlined_button.dart';

/// The top of a playlist's page: picture, name, song count, and the Play and
/// Shuffle buttons. Both buttons are off while no song can be played.
class PlaylistHeader extends StatelessWidget {
  final Playlist playlist;
  final bool canPlay;
  final VoidCallback onPlay;
  final VoidCallback onShuffle;

  const PlaylistHeader({
    super.key,
    required this.playlist,
    required this.canPlay,
    required this.onPlay,
    required this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    final count = playlist.items.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlaylistArt(
                seed: playlist.id,
                isLiked: playlist.isLiked,
                size: 64,
                radius: AppShape.panel,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      style: AppType.display,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(Labels.songCount(count), style: AppType.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _PlayButton(enabled: canPlay, onPressed: onPlay),
              const SizedBox(width: 10),
              SwarOutlinedButton(
                label: Labels.shuffleAll,
                onPressed: canPlay ? onShuffle : null,
              ),
            ],
          ),
          if (playlist.isEditable && count > 1) ...[
            const SizedBox(height: 10),
            Text(Words.playlistReorderHint, style: AppType.caption),
          ],
        ],
      ),
    );
  }
}

/// The filled rose Play button, sharp-cornered like the outlined one.
class _PlayButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _PlayButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppShape.button),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SwarIcon(
                    glyph: SwarGlyph.play,
                    size: 16,
                    color: AppColors.onAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Labels.playAll,
                    style:
                        AppType.bodyMuted.copyWith(color: AppColors.onAccent),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
