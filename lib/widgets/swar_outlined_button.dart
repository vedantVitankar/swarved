import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/shape.dart';
import '../theme/typography.dart';

/// The app's outlined button: sharp corners, a rose outline, rose words.
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
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.accent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShape.button),
        ),
        padding: padding,
      ),
      child: Text(
        label,
        style: AppType.bodyMuted.copyWith(color: AppColors.accent),
      ),
    );
  }
}
