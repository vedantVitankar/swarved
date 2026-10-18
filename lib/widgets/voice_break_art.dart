import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/swar_glyphs.dart';
import 'swar_icon.dart';

/// What stands in for a song's artwork while one of his recordings plays
/// between songs: a velvet square with a rose heart, so it never looks like
/// an advert.
class VoiceBreakArt extends StatelessWidget {
  final double size;
  final double iconSize;
  final double radius;

  const VoiceBreakArt({
    super.key,
    required this.size,
    required this.iconSize,
    this.radius = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.maroon,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: SwarIcon(
        glyph: SwarGlyph.heartFilled,
        size: iconSize,
        color: AppColors.accent,
      ),
    );
  }
}
