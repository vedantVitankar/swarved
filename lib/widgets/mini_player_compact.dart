import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content/labels.dart';
import '../models/track.dart';
import '../screens/now_playing_screen.dart';
import '../services/player_service.dart';
import '../theme/colors.dart';
import '../theme/responsive.dart';
import '../theme/shape.dart';
import '../theme/typography.dart';
import 'compact_icon_button.dart';
import 'heart_button.dart';
import 'play_pause_button.dart';
import 'swipe_to_skip.dart';
import 'track_artwork.dart';
import 'track_subtitle.dart';

/// The phone-sized mini player: artwork and title on the left (swipe them
/// to skip), heart and play/pause on the right, a thin progress line along
/// the bottom. Tap anywhere that isn't a button to open Now Playing.
class MiniPlayerCompact extends StatelessWidget {
  final Track track;
  final bool canPrevious;
  final bool canNext;

  const MiniPlayerCompact({
    super.key,
    required this.track,
    required this.canPrevious,
    required this.canNext,
  });

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
    final player = context.read<PlayerService>();
    final showSkipButtons = _showSkipButtons(context);

    return InkWell(
      onTap: () => NowPlayingScreen.open(context),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(track.title,
                                  style: AppType.body,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              TrackSubtitle(
                                track: track,
                                style: AppType.caption,
                              ),
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
                    tooltip: Labels.previousSong,
                    onPressed: player.restartOrPrevious,
                  ),
                const PlayPauseButton.glyph(),
                if (showSkipButtons)
                  CompactIconButton(
                    icon: Icons.skip_next,
                    tooltip: Labels.nextSong,
                    onPressed: player.next,
                  ),
              ],
            ),
          ),
          const _MiniProgressBar(),
        ],
      ),
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
