import 'package:flutter/material.dart';
import '../../content/labels.dart';
import '../../theme/colors.dart';

/// Where she is in the welcome: one small dot per step, the current one
/// stretched out and gold.
class WelcomeDots extends StatelessWidget {
  final int count;
  final int index;

  const WelcomeDots({super.key, required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: Labels.welcomeStep(index + 1, count),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == index ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == index ? AppColors.gold : AppColors.hairline,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}
