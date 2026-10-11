import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../utils/playlist_resolve.dart';
import '../theme/swar_glyphs.dart';
import 'folder_art.dart';
import 'swar_icon.dart';
import 'track_artwork.dart';

/// The picture for a playlist. Liked songs gets a rose heart, always the
/// same. Any other playlist shows its first four songs' pictures in a 2 by 2
/// grid; with one to three pictures it shows the first alone; with none it
/// gets a colour block from its id, like a folder, so it keeps its colour on
/// every run.
class PlaylistArt extends StatelessWidget {
  final String seed;
  final bool isLiked;
  final double size;
  final double radius;

  /// The pictures of the playlist's first songs, see [playlistCovers].
  final List<PlaylistCover> covers;

  const PlaylistArt({
    super.key,
    required this.seed,
    this.isLiked = false,
    this.size = 46,
    this.radius = 0,
    this.covers = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (!isLiked && covers.isNotEmpty) return _mosaic();
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

  Widget _mosaic() {
    Widget cell(PlaylistCover cover, double cellSize) => TrackArtwork(
          bytes: cover.bytes,
          url: cover.url,
          size: cellSize,
          iconSize: cellSize * 0.4,
        );

    final Widget picture;
    if (covers.length >= 4) {
      final half = size / 2;
      picture = Column(
        children: [
          Row(children: [cell(covers[0], half), cell(covers[1], half)]),
          Row(children: [cell(covers[2], half), cell(covers[3], half)]),
        ],
      );
    } else {
      picture = cell(covers.first, size);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: size, height: size, child: picture),
    );
  }
}
