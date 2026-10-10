import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../services/player_service.dart';
import '../theme/colors.dart';
import '../theme/responsive.dart';
import '../theme/shape.dart';
import '../tutorial/tutorial_controller.dart';
import '../tutorial/tutorial_step.dart';
import 'mini_player_compact.dart';
import 'mini_player_desktop.dart';

/// The velvet card floating above the tab bar. This is only the frame:
/// the margin, the rounded card and the choice of layout. Wide windows get
/// the three-zone desktop layout, everything else the compact one.
/// Hidden when nothing plays.
class MiniPlayerBar extends StatelessWidget {
  /// True when nothing sits below the bar (wide layouts, folder pages), so
  /// the bar keeps clear of the system bar itself.
  final bool padBottom;

  const MiniPlayerBar({super.key, this.padBottom = false});

  static const double _margin = 8;

  @override
  Widget build(BuildContext context) {
    // Only rebuilds when the current TRACK changes, or when whether a skip
    // is possible changes (shuffle and repeat affect that) — not on every
    // position tick. This is what stops the artwork/title from flickering
    // while playing. The progress line and seek bar rebuild on their own.
    return Selector<PlayerService, (Track?, bool, bool)>(
      selector: (_, player) =>
          (player.current, player.canGoPrevious, player.canGoNext),
      builder: (context, data, _) {
        final (track, canPrevious, canNext) = data;
        if (track == null) return const SizedBox.shrink();

        final desktop = Responsive.of(MediaQuery.sizeOf(context).width) ==
            ScreenClass.expanded;

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
                constraints: BoxConstraints(
                  maxWidth: desktop
                      ? Responsive.desktopPlayerMaxWidth
                      : Responsive.contentMaxWidth,
                ),
                child: Material(
                  // The tour's spotlight finds the player by this key.
                  key: TutorialScope.read(context)?.keyFor(TutorialStep.player),
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppShape.panel),
                  clipBehavior: Clip.antiAlias,
                  child: desktop
                      ? MiniPlayerDesktop(track: track)
                      : MiniPlayerCompact(
                          track: track,
                          canPrevious: canPrevious,
                          canNext: canNext,
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
