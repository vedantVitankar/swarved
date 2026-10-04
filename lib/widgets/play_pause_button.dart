import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../theme/colors.dart';
import 'compact_icon_button.dart';

enum PlayPauseStyle { glyph, disc }

/// Used by both MiniPlayerBar and NowPlayingScreen. Selector-scoped to
/// isPlaying only, so it does NOT rebuild on every position tick — only
/// when play/pause actually toggles.
class PlayPauseButton extends StatelessWidget {
  final PlayPauseStyle style;
  final double size;

  /// A plain cream glyph, for the mini player.
  const PlayPauseButton.glyph({super.key, this.size = 40})
      : style = PlayPauseStyle.glyph;

  /// The cream disc from the preview, for Now Playing.
  const PlayPauseButton.disc({super.key, this.size = 54})
      : style = PlayPauseStyle.disc;

  @override
  Widget build(BuildContext context) {
    return Selector<PlayerService, bool>(
      selector: (_, player) => player.isPlaying,
      builder: (context, isPlaying, _) {
        final player = context.read<PlayerService>();
        final isDisc = style == PlayPauseStyle.disc;
        return CompactIconButton(
          icon: isPlaying ? Icons.pause : Icons.play_arrow,
          boxSize: size,
          iconSize: isDisc ? size * 0.52 : 28,
          color: isDisc ? AppColors.base : AppColors.textPrimary,
          background: isDisc ? AppColors.textPrimary : null,
          onPressed: player.togglePlayPause,
        );
      },
    );
  }
}
