import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content/labels.dart';
import '../models/track.dart';
import '../services/player_service.dart';
import '../theme/colors.dart';
import '../theme/shape.dart';
import '../theme/swar_glyphs.dart';
import '../theme/typography.dart';
import '../widgets/compact_icon_button.dart';
import '../widgets/heart_button.dart';
import '../widgets/play_pause_button.dart';
import '../widgets/playback_mode_buttons.dart';
import '../widgets/seek_bar.dart';
import '../widgets/swar_icon.dart';
import '../widgets/track_artwork.dart';
import '../widgets/track_note_card.dart';
import '../widgets/track_subtitle.dart';

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

  /// Rough height of everything under the artwork (title, seek bar,
  /// controls, the note card and the gaps). The artwork takes whatever is
  /// left; if the window is still too short, the page scrolls instead of
  /// overflowing.
  static const double _reservedHeight = 380;

  /// "Playing from Slow dances" for a folder song, or the search for a
  /// YouTube song, which has no folder.
  static String _playingFrom(Track track) =>
      track.isLocal && track.folder.isNotEmpty
          ? Labels.playingFrom(track.folder)
          : Labels.playingFromSearch;

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
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const SwarIcon(
                glyph: SwarGlyph.down,
                size: 28,
                color: AppColors.textPrimary,
              ),
              tooltip: Labels.closePlayer,
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              _playingFrom(track),
              style: AppType.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                              url: track.artworkUrl,
                              sharpPixels: 544,
                              size: artSize,
                              iconSize: 64,
                              radius: AppShape.panel,
                            ),
                            const SizedBox(height: 20),
                            // Title and artist on the left, the heart on the
                            // right, as in the preview.
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(track.title,
                                          style: AppType.trackTitle,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      TrackSubtitle(
                                        track: track,
                                        style: AppType.bodyMuted,
                                        textAlign: TextAlign.start,
                                      ),
                                    ],
                                  ),
                                ),
                                const HeartButton(iconSize: 26),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const SeekBar(),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const ShuffleButton(),
                                CompactIconButton(
                                  icon: SwarGlyph.previous,
                                  tooltip: Labels.previousSong,
                                  iconSize: 26,
                                  boxSize: 44,
                                  onPressed: player.restartOrPrevious,
                                ),
                                const PlayPauseButton.disc(),
                                CompactIconButton(
                                  icon: SwarGlyph.next,
                                  tooltip: Labels.nextSong,
                                  iconSize: 26,
                                  boxSize: 44,
                                  onPressed: player.next,
                                ),
                                const RepeatButton(),
                              ],
                            ),
                            // His handwritten note for this song, if any.
                            TrackNoteCard(track: track),
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
