import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content/labels.dart';
import '../services/player_service.dart';
import '../theme/colors.dart';
import '../theme/swar_glyphs.dart';
import '../utils/queue_order.dart';
import 'compact_icon_button.dart';

/// Shuffle on or off. The icon lights up in rose when it's on.
class ShuffleButton extends StatelessWidget {
  const ShuffleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<PlayerService, bool>(
      selector: (_, player) => player.shuffle,
      builder: (context, isOn, _) {
        return CompactIconButton(
          icon: SwarGlyph.shuffle,
          color: isOn ? AppColors.accent : AppColors.textSecondary,
          tooltip: isOn ? Labels.shuffleOff : Labels.shuffleOn,
          onPressed: context.read<PlayerService>().toggleShuffle,
        );
      },
    );
  }
}

/// Repeat: off, then all, then one. Each tap moves to the next.
class RepeatButton extends StatelessWidget {
  const RepeatButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<PlayerService, QueueRepeat>(
      selector: (_, player) => player.repeat,
      builder: (context, mode, _) {
        // The tooltip names what the NEXT tap will do.
        final (icon, tooltip) = switch (mode) {
          QueueRepeat.off => (SwarGlyph.repeat, Labels.repeatAll),
          QueueRepeat.all => (SwarGlyph.repeat, Labels.repeatOne),
          QueueRepeat.one => (SwarGlyph.repeatOne, Labels.repeatOff),
        };
        return CompactIconButton(
          icon: icon,
          color: mode == QueueRepeat.off
              ? AppColors.textSecondary
              : AppColors.accent,
          tooltip: tooltip,
          onPressed: context.read<PlayerService>().cycleRepeat,
        );
      },
    );
  }
}
