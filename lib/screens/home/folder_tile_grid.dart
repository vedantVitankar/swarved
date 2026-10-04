import 'package:flutter/material.dart';
import '../../models/track.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/typography.dart';
import '../../widgets/folder_art.dart';

/// The folder tiles on Home: colour block on the left, name beside it.
/// Shows the biggest folders first; the Library tab will list them all.
class FolderTileGrid extends StatelessWidget {
  final Map<String, List<Track>> byFolder;
  final void Function(String folder, List<Track> tracks) onOpenFolder;

  const FolderTileGrid({
    super.key,
    required this.byFolder,
    required this.onOpenFolder,
  });

  static const _maxTiles = 8;

  @override
  Widget build(BuildContext context) {
    final shown = (byFolder.entries.toList()
          ..sort((a, b) => b.value.length.compareTo(a.value.length)))
        .take(_maxTiles)
        .toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      // Two columns on a phone, more on a wide window.
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisExtent: 46,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: shown.length,
      itemBuilder: (context, i) {
        final entry = shown[i];
        return _FolderTile(
          name: entry.key,
          onTap: () => onOpenFolder(entry.key, entry.value),
        );
      },
    );
  }
}

class _FolderTile extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _FolderTile({required this.name, required this.onTap});

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
            FolderArt(seed: name, size: 46),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  name,
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
