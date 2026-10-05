import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Colour block that stands in for a folder's artwork, as in the preview.
/// Each folder name always gets the same colour.
class FolderArt extends StatelessWidget {
  final String seed;
  final double size;
  final double radius;

  const FolderArt(
      {super.key, required this.seed, this.size = 46, this.radius = 0});

  static const _palette = [
    AppColors.wine,
    AppColors.maroon,
    AppColors.accent,
    AppColors.gold,
    AppColors.surfaceRaised,
  ];

  /// Which palette colour a name gets. Plain arithmetic instead of
  /// String.hashCode, so a folder keeps its colour on every run.
  static int paletteIndex(String seed) {
    var h = 0;
    for (final unit in seed.codeUnits) {
      h = (h * 31 + unit) % 1000000007;
    }
    return h % _palette.length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _palette[paletteIndex(seed)],
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
