import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// A small deterministic bar visualization seeded from a string (e.g. a
/// track path), used as a decorative-but-consistent "meter" readout in the
/// logbook module. Same input always produces the same bars.
class MiniWaveform extends StatelessWidget {
  final String seed;
  final int barCount;
  final double height;
  final Color color;

  const MiniWaveform({
    super.key,
    required this.seed,
    this.barCount = 24,
    this.height = 28,
    this.color = AppColors.meter,
  });

  @override
  Widget build(BuildContext context) {
    final rand = Random(seed.hashCode);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(barCount, (i) {
          final level = 0.25 + rand.nextDouble() * 0.75;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              height: height * level,
              decoration: BoxDecoration(
                color: color.withOpacity(0.75),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
        }),
      ),
    );
  }
}
