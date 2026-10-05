import 'package:flutter/material.dart';
import '../content/labels.dart';
import '../theme/colors.dart';
import '../theme/shape.dart';
import '../theme/typography.dart';
import 'folder_art.dart';

/// One folder in the Library list: colour block, name, song count.
/// The folder being played from gets a rose name.
class FolderRow extends StatelessWidget {
  final String name;
  final int songCount;
  final bool isPlaying;
  final VoidCallback onTap;

  const FolderRow({
    super.key,
    required this.name,
    required this.songCount,
    required this.onTap,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppShape.tile),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(
            children: [
              FolderArt(seed: name, size: 46, radius: AppShape.thumbnail),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: AppType.body.copyWith(
                        color: isPlaying
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(Labels.songCount(songCount), style: AppType.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
