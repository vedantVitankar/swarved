import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../theme/colors.dart';

/// Used by both MiniPlayerBar and NowPlayingScreen. Selector-scoped to
/// isPlaying only, so it does NOT rebuild on every position tick — only
/// when play/pause actually toggles.
class PlayPauseButton extends StatelessWidget {
  final double size;
  const PlayPauseButton({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Selector<PlayerService, bool>(
      selector: (_, player) => player.isPlaying,
      builder: (context, isPlaying, _) {
        final player = context.read<PlayerService>();
        return IconButton(
          iconSize: size,
          icon: Icon(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: AppColors.accent,
          ),
          onPressed: player.togglePlayPause,
        );
      },
    );
  }
}