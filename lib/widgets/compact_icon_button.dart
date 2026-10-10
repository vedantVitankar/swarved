import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/swar_glyphs.dart';
import 'swar_icon.dart';

/// A round icon button with an exact size (40 by default), shared by the
/// mini player's controls, the heart and the cream play disc.
/// Press and hover show the theme's soft blush. The [tooltip] names the
/// button on hover (Windows) and to screen readers.
class CompactIconButton extends StatelessWidget {
  final SwarGlyph icon;
  final VoidCallback? onPressed;

  /// Optional. Held down instead of tapped.
  final VoidCallback? onLongPress;
  final String? tooltip;
  final Color color;
  final Color? background;
  final double iconSize;
  final double boxSize;

  /// Shows a small spinner in place of the icon while something loads.
  final bool busy;

  const CompactIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.onLongPress,
    this.tooltip,
    this.color = AppColors.textPrimary,
    this.background,
    this.iconSize = 24,
    this.boxSize = 40,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = SizedBox.square(
      dimension: boxSize,
      child: Material(
        color: background ?? Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          onLongPress: onLongPress,
          child: Center(
            child: busy
                ? SizedBox.square(
                    dimension: iconSize * 0.8,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                : SwarIcon(glyph: icon, size: iconSize, color: color),
          ),
        ),
      ),
    );

    final label = tooltip;
    if (label == null) return button;
    return Tooltip(
      message: label,
      // A tooltip also listens for a long press on touch screens, which
      // would compete with the button's own.
      triggerMode: onLongPress == null ? null : TooltipTriggerMode.manual,
      child: button,
    );
  }
}
