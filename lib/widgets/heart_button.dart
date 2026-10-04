import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'compact_icon_button.dart';

/// A dummy for now: it looks and reacts like a heart but keeps no state.
/// Later, a favourites feature only has to pass [isFilled] and [onPressed].
class HeartButton extends StatelessWidget {
  final bool isFilled;
  final VoidCallback? onPressed;

  const HeartButton({super.key, this.isFilled = false, this.onPressed});

  // A button with no handler would let the tap fall through to the card
  // behind it (and open Now Playing), so the dummy always has one.
  static void _absorbTap() {}

  @override
  Widget build(BuildContext context) {
    return CompactIconButton(
      icon: isFilled ? Icons.favorite : Icons.favorite_border,
      iconSize: 22,
      color: AppColors.accent,
      onPressed: onPressed ?? _absorbTap,
    );
  }
}
