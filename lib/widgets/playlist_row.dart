import 'package:flutter/material.dart';
import '../content/labels.dart';
import '../models/playlist.dart';
import '../theme/colors.dart';
import '../theme/shape.dart';
import '../theme/typography.dart';
import 'playlist_art.dart';

/// One playlist in the Library list: picture, name, song count. Liked songs
/// says it is pinned.
class PlaylistRow extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;

  const PlaylistRow({super.key, required this.playlist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final count = playlist.items.length;
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
              PlaylistArt(
                seed: playlist.id,
                isLiked: playlist.isLiked,
                size: 46,
                radius: AppShape.thumbnail,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      playlist.name,
                      style: AppType.body.copyWith(color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      playlist.isLiked
                          ? Labels.pinnedSongCount(count)
                          : Labels.songCount(count),
                      style: AppType.caption,
                    ),
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
