import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/swar_glyphs.dart';
import 'folder_art.dart';
import 'swar_icon.dart';

/// The picture for a playlist. Liked songs gets a rose heart, always the
/// same; every other playlist gets a colour block from its id, like a
/// folder, so it keeps its colour on every run.
class PlaylistArt extends StatelessWidget {
  final String seed;
  final bool isLiked;
  final double size;
  final double radius;

  const PlaylistArt({
    super.key,
    required this.seed,
    this.isLiked = false,
    this.size = 46,
    this.radius = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLiked) return FolderArt(seed: seed, size: size, radius: radius);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.rosewood, AppColors.maroon],
        ),
      ),
      child: Center(
        child: SwarIcon(
          glyph: SwarGlyph.heartFilled,
          size: size * 0.5,
          color: AppColors.blush,
        ),
      ),
    );
  }
}
