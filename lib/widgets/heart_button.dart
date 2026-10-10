import 'package:flutter/material.dart';
import '../content/labels.dart';
import '../theme/colors.dart';
import '../theme/swar_glyphs.dart';
import 'compact_icon_button.dart';

/// The heart's look: outline or solid, with a tap and a long press. It keeps
/// no state of its own. TrackHeart gives it one song's state and actions.
/// With no handler it absorbs the tap, so nothing behind it reacts.
class HeartButton extends StatelessWidget {
  final bool isFilled;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final double iconSize;

  const HeartButton({
    super.key,
    this.isFilled = false,
    this.onPressed,
    this.onLongPress,
    this.iconSize = 22,
  });

  // A button with no handler would let the tap fall through to the card
  // behind it (and open Now Playing), so it always has one.
  static void _absorbTap() {}

  @override
  Widget build(BuildContext context) {
    return CompactIconButton(
      icon: isFilled ? SwarGlyph.heartFilled : SwarGlyph.heart,
      iconSize: iconSize,
      tooltip: isFilled ? Labels.unheartSong : Labels.heartSong,
      color: AppColors.accent,
      onPressed: onPressed ?? _absorbTap,
      onLongPress: onLongPress,
    );
  }
}
