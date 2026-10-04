import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../screens/now_playing_screen.dart';
import '../services/player_service.dart';
import '../theme/colors.dart';
import '../theme/shape.dart';
import '../theme/typography.dart';
import 'compact_icon_button.dart';
import 'heart_button.dart';
import 'page_body.dart';
import 'play_pause_button.dart';
import 'swipe_to_skip.dart';
import 'track_artwork.dart';
import '../theme/responsive.dart';

/// The velvet card floating above the tab bar. Tap it to open Now Playing;
/// swipe the song area left or right to skip. Hidden when nothing plays.
class MiniPlayerBar extends StatelessWidget {
  /// True when nothing sits below the bar (wide layouts, folder pages), so
  /// the bar keeps clear of the system bar itself.
  final bool padBottom;

  const MiniPlayerBar({super.key, this.padBottom = false});

  static const double _margin = 8;
  static const double _button = 40;

  /// Phones in portrait swipe to skip, so the skip buttons only show where
  /// swiping is awkward: wide screens, landscape phones, and any mouse
  /// (Windows) layout, even in a narrow window.
  static bool _showSkipButtons(BuildContext context) {
    final narrow =
        Responsive.of(MediaQuery.sizeOf(context).width) == ScreenClass.compact;
    final touch = switch (Theme.of(context).platform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
    return !(narrow && touch);
  }

  @override
  Widget build(BuildContext context) {
    // Only rebuilds when the current TRACK changes (not on every position
    // tick) — this is what stops the artwork/title from flickering while
    // playing. The progress line handles its own, faster rebuild scope.
    return Selector<PlayerService, Track?>(
      selector: (_, player) => player.current,
      builder: (context, track, _) {
        if (track == null) return const SizedBox.shrink();
        final player = context.read<PlayerService>();
        final canPrevious = player.currentIndex > 0;
        final canNext = player.currentIndex < player.queue.length - 1;

        final showSkipButtons = _showSkipButtons(context);

        return SafeArea(
          top: false,
          left: false,
          right: false,
          bottom: padBottom,
          child: Padding(
            padding: const EdgeInsets.all(_margin),
            // Align, not Center: this bar is also used as a Scaffold's
            // bottomNavigationBar, where Center would grab the full height.
            child: Align(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: PageBody.maxWidth),
                child: Material(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppShape.panel),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NowPlayingScreen(),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Expanded(
                                child: SwipeToSkip(
                                  canPrevious: canPrevious,
                                  canNext: canNext,
                                  onPrevious: player.previous,
                                  onNext: player.next,
                                  child: Row(
                                    children: [
                                      TrackArtwork(
                                        bytes: track.artworkBytes,
                                        size: _button,
                                        iconSize: 18,
                                        radius: AppShape.thumbnail,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(track.title,
                                                style: AppType.body,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                            Text(track.artist,
                                                style: AppType.caption,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const HeartButton(),
                              if (showSkipButtons)
                                CompactIconButton(
                                  icon: Icons.skip_previous,
                                  onPressed: player.previous,
                                ),
                              const PlayPauseButton.glyph(),
                              if (showSkipButtons)
                                CompactIconButton(
                                  icon: Icons.skip_next,
                                  onPressed: player.next,
                                ),
                            ],
                          ),
                        ),
                        const _MiniProgressBar(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Isolated so ONLY this thin line rebuilds on every position tick — the
/// artwork/title row above it does not.
class _MiniProgressBar extends StatelessWidget {
  const _MiniProgressBar();

  @override
  Widget build(BuildContext context) {
    return Selector<PlayerService, (Duration, Duration)>(
      selector: (_, player) => (player.position, player.duration),
      builder: (context, data, _) {
        final (pos, dur) = data;
        final progress = dur.inMilliseconds > 0
            ? pos.inMilliseconds / dur.inMilliseconds
            : 0.0;
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
