import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/typography.dart';
import '../../utils/home_tiles.dart';
import '../../widgets/folder_art.dart';
import '../../widgets/playlist_art.dart';

/// The tiles on Home: colour block on the left, name beside it, two columns
/// by three rows. What fills them is chosen by [pickHomeTiles].
class HomeTileGrid extends StatelessWidget {
  final List<HomeTile> tiles;
  final void Function(HomeTile tile) onOpen;

  const HomeTileGrid({super.key, required this.tiles, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 46,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, i) {
        final tile = tiles[i];
        return _Tile(tile: tile, onTap: () => onOpen(tile));
      },
    );
  }
}

class _Tile extends StatelessWidget {
  final HomeTile tile;
  final VoidCallback onTap;

  const _Tile({required this.tile, required this.onTap});

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
                ? PlaylistArt(seed: tile.id, isLiked: tile.isLiked, size: 46)
                : FolderArt(seed: tile.name, size: 46),
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
