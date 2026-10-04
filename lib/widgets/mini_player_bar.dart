import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../screens/now_playing_screen.dart';
import '../services/player_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'play_pause_button.dart';
import 'track_artwork.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Only rebuilds when the current TRACK changes (not on every position
    // tick) — this is what stops the artwork/title from flickering while
    // playing. The progress bar below handles its own, separate,
    // fast-updating rebuild scope.
    return Selector<PlayerService, Track?>(
      selector: (_, player) => player.current,
      builder: (context, track, _) {
        if (track == null) return const SizedBox.shrink();
        final player = context.read<PlayerService>();

        return InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.hairline)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _MiniProgressBar(),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      TrackArtwork(
                        bytes: track.artworkBytes,
                        size: 36,
                        iconSize: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(track.title,
                                style: AppType.body,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(track.artist,
                                style: AppType.bodyMuted,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        onPressed: player.previous,
                      ),
                      const PlayPauseButton(size: 32),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        onPressed: player.next,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Isolated so ONLY this thin bar rebuilds on every position tick — the
/// artwork/title row above it (in MiniPlayerBar) no longer does.
class _MiniProgressBar extends StatelessWidget {
  const _MiniProgressBar();

  @override
  Widget build(BuildContext context) {
    return Selector<PlayerService, (Duration, Duration)>(
      selector: (_, player) => (player.position, player.duration),
      builder: (context, data, _) {
        final (pos, dur) = data;
        final progress =
            dur.inMilliseconds > 0 ? pos.inMilliseconds / dur.inMilliseconds : 0.0;
        return SizedBox(
          height: 2,
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: AppColors.hairline,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          ),
        );
      },
    );
  }
}