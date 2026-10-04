import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// A round icon button with an exact size (40 by default), shared by the
/// mini player's controls, the heart and the cream play disc.
/// Press and hover show the theme's soft blush.
class CompactIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final Color? background;
  final double iconSize;
  final double boxSize;

  const CompactIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.textPrimary,
    this.background,
    this.iconSize = 24,
    this.boxSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: boxSize,
      child: Material(
        color: background ?? Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Center(child: Icon(icon, size: iconSize, color: color)),
        ),
      ),
    );
  }
}
