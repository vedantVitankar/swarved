import 'package:flutter/material.dart';
import '../content/labels.dart';
import '../theme/colors.dart';
import '../theme/swar_glyphs.dart';
import 'compact_icon_button.dart';

/// A dummy for now: it looks and reacts like a heart but keeps no state.
/// Later, a favourites feature only has to pass [isFilled] and [onPressed].
class HeartButton extends StatelessWidget {
  final bool isFilled;
  final VoidCallback? onPressed;
  final double iconSize;

  const HeartButton({
    super.key,
    this.isFilled = false,
    this.onPressed,
    this.iconSize = 22,
  });

  // A button with no handler would let the tap fall through to the card
  // behind it (and open Now Playing), so the dummy always has one.
  static void _absorbTap() {}

  @override
  Widget build(BuildContext context) {
    return CompactIconButton(
      icon: isFilled ? SwarGlyph.heartFilled : SwarGlyph.heart,
      iconSize: iconSize,
      tooltip: isFilled ? Labels.unheartSong : Labels.heartSong,
      color: AppColors.accent,
      onPressed: onPressed ?? _absorbTap,
    );
  }
}