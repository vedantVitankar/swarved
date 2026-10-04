import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../services/player_service.dart';
import '../theme/colors.dart';
import '../theme/shape.dart';
import '../theme/typography.dart';
import '../utils/duration_format.dart';
import '../widgets/compact_icon_button.dart';
import '../widgets/play_pause_button.dart';
import '../widgets/track_artwork.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  static const double _sidePadding = 28;
  static const double _maxContentWidth = 420;
  static const double _minArtwork = 120;

  /// Rough height of everything under the artwork (title, artist, seek bar,
  /// controls and gaps). The artwork takes whatever is left; if the window
  /// is still too short, the page scrolls instead of overflowing.
  static const double _reservedHeight = 300;

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
            child: LayoutBuilder(
              builder: (context, box) {
                final contentWidth = math.max(
                  0.0,
                  math.min(box.maxWidth - 2 * _sidePadding, _maxContentWidth),
                );
                final artSize = math.min(
                  contentWidth,
                  math.max(_minArtwork, box.maxHeight - _reservedHeight),
                );

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: Center(
                      child: SizedBox(
                        width: contentWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TrackArtwork(
                              bytes: track.artworkBytes,
                              size: artSize,
                              iconSize: 64,
                              radius: AppShape.panel,
                            ),
                            const SizedBox(height: 28),
                            Text(track.title,
                                style: AppType.trackTitle,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Text(track.artist,
                                style: AppType.bodyMuted,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 24),
                            const _SeekBar(),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                CompactIconButton(
                                  icon: Icons.skip_previous,
                                  iconSize: 32,
                                  boxSize: 48,
                                  onPressed: player.previous,
                                ),
                                const PlayPauseButton.disc(),
                                CompactIconButton(
                                  icon: Icons.skip_next,
                                  iconSize: 32,
                                  boxSize: 48,
                                  onPressed: player.next,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
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
              value: pos.inMilliseconds.clamp(0, dur.inMilliseconds).toDouble(),
              onChanged: (v) => player.seek(Duration(milliseconds: v.round())),
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
