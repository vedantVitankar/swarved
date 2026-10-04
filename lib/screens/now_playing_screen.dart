import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../services/player_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/duration_format.dart';
import '../widgets/play_pause_button.dart';
import '../widgets/track_artwork.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Only rebuilds when the current TRACK changes — artwork/title/artist
    // stay stable across the many position-tick notifications per second.
    return Selector<PlayerService, Track?>(
      selector: (_, player) => player.current,
      builder: (context, track, _) {
        if (track == null) {
          return Scaffold(
            backgroundColor: AppColors.base,
            body: Center(
              child: Text('Nothing playing', style: AppType.bodyMuted),
            ),
          );
        }

        final player = context.read<PlayerService>();

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

                  const _SeekBar(),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        iconSize: 32,
                        icon: const Icon(Icons.skip_previous),
                        onPressed: player.previous,
                      ),
                      const PlayPauseButton(size: 64),
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
      },
    );
  }
}

/// Isolated so ONLY the slider + time labels rebuild on every position
/// tick — the artwork/title above no longer gets pulled into that.
class _SeekBar extends StatelessWidget {
  const _SeekBar();

  @override
  Widget build(BuildContext context) {
    return Selector<PlayerService, (Duration, Duration)>(
      selector: (_, player) => (player.position, player.duration),
      builder: (context, data, _) {
        final (pos, dur) = data;
        final player = context.read<PlayerService>();
        return Column(
          children: [
            Slider(
              min: 0,
              max: dur.inMilliseconds.toDouble().clamp(1, double.infinity),
              value:
                  pos.inMilliseconds.clamp(0, dur.inMilliseconds).toDouble(),
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
          ],
        );
      },
    );
  }
}