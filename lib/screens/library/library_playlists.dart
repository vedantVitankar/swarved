import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/labels.dart';
import '../../content/words.dart';
import '../../services/playlist_service.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/swar_glyphs.dart';
import '../../theme/typography.dart';
import '../../widgets/playlist_name_dialog.dart';
import '../../widgets/playlist_row.dart';
import '../../widgets/swar_icon.dart';
import '../playlist/playlist_screen.dart';

/// The Playlists view in the Library: a New playlist row, Liked songs, then
/// her playlists. It needs no music folder, because a playlist can hold
/// YouTube songs.
class LibraryPlaylists extends StatelessWidget {
  const LibraryPlaylists({super.key});

  /// Asks for a name, makes the playlist and opens it.
  static Future<void> _create(BuildContext context) async {
    final service = context.read<PlaylistService>();
    final name = await showPlaylistNameDialog(
      context,
      title: Labels.newPlaylist,
      confirmLabel: Labels.createPlaylist,
    );
    if (name == null) return;
    final created = service.create(name);
    if (created == null || !context.mounted) return;
    PlaylistScreen.open(context, created.id);
  }

  @override
  Widget build(BuildContext context) {
    final playlists = context.watch<PlaylistService>().playlists;
    final onlyLiked = playlists.length <= 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NewPlaylistRow(onTap: () => _create(context)),
        for (final playlist in playlists)
          PlaylistRow(
            playlist: playlist,
            onTap: () => PlaylistScreen.open(context, playlist.id),
          ),
        if (onlyLiked)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Text(Words.playlistsHint, style: AppType.bodyMuted),
          ),
      ],
    );
  }
}

/// The first row: a plus on a velvet block, in the shape of a playlist row.
class _NewPlaylistRow extends StatelessWidget {
  final VoidCallback onTap;

  const _NewPlaylistRow({required this.onTap});

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
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppShape.thumbnail),
                ),
                child: const Center(
                  child: SwarIcon(
                    glyph: SwarGlyph.add,
                    size: 22,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  Labels.newPlaylist,
                  style: AppType.body.copyWith(color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
