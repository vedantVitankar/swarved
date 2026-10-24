import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/typography.dart';
import '../../utils/home_tiles.dart';
import '../../widgets/folder_art.dart';
import '../../widgets/playlist_picture.dart';

/// The tiles on Home: colour block on the left, name beside it, two columns
/// by three rows (three by two on wide windows, with a taller tile). What
/// fills them is chosen by [pickHomeTiles].
class HomeTileGrid extends StatelessWidget {
  final List<HomeTile> tiles;
  final void Function(HomeTile tile) onOpen;
  final int columns;

  const HomeTileGrid({
    super.key,
    required this.tiles,
    required this.onOpen,
    this.columns = 2,
  });

  /// The colour block is a square the height of the tile.
  double get tileSize => columns > 2 ? 56 : 46;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisExtent: tileSize,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, i) {
        final tile = tiles[i];
        return _Tile(tile: tile, size: tileSize, onTap: () => onOpen(tile));
      },
    );
  }
}

class _Tile extends StatelessWidget {
  final HomeTile tile;
  final double size;
  final VoidCallback onTap;

  const _Tile({required this.tile, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppShape.tile),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            tile.kind == HomeTileKind.playlist
                ? PlaylistPicture(playlistId: tile.id, size: size)
                : FolderArt(seed: tile.name, size: size),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  tile.name,
                  style: AppType.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
