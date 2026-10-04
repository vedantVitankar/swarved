import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// The small sun that stands in for artwork on quiet screens.
/// Gold, because Swarnima means sunlight.
class SunMark extends StatelessWidget {
  final double size;
  const SunMark({super.key, this.size = 84});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          // The HTML measures corner to corner, which is 0.7071 of the box.
          // Using the same radius puts every ring exactly where the preview has it.
          radius: 0.7071,
          colors: [
            AppColors.goldLight,
            AppColors.goldLight,
            AppColors.gold,
            AppColors.gold,
            AppColors.gold.withAlpha(64),
            AppColors.gold.withAlpha(64),
          ],
          stops: const [0.0, 0.38, 0.39, 0.60, 0.61, 1.0],
        ),
      ),
    );
  }
}
