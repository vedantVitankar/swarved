import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content/labels.dart';
import '../models/track.dart';
import '../services/player_service.dart';
import '../theme/colors.dart';
import '../theme/shape.dart';
import '../theme/typography.dart';
import '../widgets/compact_icon_button.dart';
import '../widgets/play_pause_button.dart';
import '../widgets/playback_mode_buttons.dart';
import '../widgets/seek_bar.dart';
import '../widgets/track_artwork.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  /// Opens the full player. Both mini player layouts go through here.
  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
    );
  }

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
              child: Text(Labels.nothingPlaying, style: AppType.bodyMuted),
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
              tooltip: Labels.closePlayer,
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
                            const SeekBar(),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const ShuffleButton(),
                                CompactIconButton(
                                  icon: Icons.skip_previous,
                                  tooltip: Labels.previousSong,
                                  iconSize: 32,
                                  boxSize: 48,
                                  onPressed: player.restartOrPrevious,
                                ),
                                const PlayPauseButton.disc(),
                                CompactIconButton(
                                  icon: Icons.skip_next,
                                  tooltip: Labels.nextSong,
                                  iconSize: 32,
                                  boxSize: 48,
                                  onPressed: player.next,
                                ),
                                const RepeatButton(),
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
