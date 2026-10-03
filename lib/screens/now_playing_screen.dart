import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/duration_format.dart';
import '../widgets/track_artwork.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final track = player.current;

    if (track == null) {
      return Scaffold(
        backgroundColor: AppColors.base,
        body: Center(
          child: Text('Nothing playing', style: AppType.bodyMuted),
        ),
      );
    }

    final pos = player.position;
    final dur = player.duration;

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        backgroundColor: AppColors.base,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: TrackArtwork(
                  bytes: track.artworkBytes,
                  size: double.infinity,
                  iconSize: 64,
                ),
              ),
              const SizedBox(height: 32),
              Text(track.title,
                  style: AppType.display.copyWith(fontSize: 22),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(track.artist, style: AppType.bodyMuted),
              const SizedBox(height: 28),

              Slider(
                min: 0,
                max: dur.inMilliseconds.toDouble().clamp(1, double.infinity),
                value: pos.inMilliseconds
                    .clamp(0, dur.inMilliseconds)
                    .toDouble(),
                onChanged: (v) =>
                    player.seek(Duration(milliseconds: v.round())),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formatDuration(pos), style: AppType.readout),
                    Text(formatDuration(dur), style: AppType.readout),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.skip_previous),
                    onPressed: player.previous,
                  ),
                  IconButton(
                    iconSize: 64,
                    icon: Icon(
                      player.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: AppColors.accent,
                    ),
                    onPressed: player.togglePlayPause,
                  ),
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.skip_next),
                    onPressed: player.next,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
