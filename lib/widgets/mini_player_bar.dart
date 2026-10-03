import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/now_playing_screen.dart';
import '../services/player_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'track_artwork.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final track = player.current;
    if (track == null) return const SizedBox.shrink();

    final pos = player.position;
    final dur = player.duration;
    final progress =
        dur.inMilliseconds > 0 ? pos.inMilliseconds / dur.inMilliseconds : 0.0;

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
            SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: AppColors.hairline,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  TrackArtwork(bytes: track.artworkBytes, size: 36, iconSize: 16),
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
                  IconButton(
                    icon: Icon(
                      player.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: AppColors.accent,
                      size: 32,
                    ),
                    onPressed: player.togglePlayPause,
                  ),
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
  }
}
