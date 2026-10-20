import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/shape.dart';
import '../theme/typography.dart';

/// The app's outlined button: sharp corners, a rose outline, rose words.
/// With no [onPressed] it is dimmed, so it looks as dead as it is.
class SwarOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;

  const SwarOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: enabled ? AppColors.accent : AppColors.hairline,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShape.button),
        ),
        padding: padding,
      ),
      child: Text(
        label,
        style: AppType.bodyMuted.copyWith(
          color: enabled ? AppColors.accent : AppColors.textFaint,
        ),
      ),
    );
  }
}
