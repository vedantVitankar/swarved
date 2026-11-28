import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/labels.dart';
import '../../content/words.dart';
import '../../services/playlist_service.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/swar_glyphs.dart';
import '../../theme/typography.dart';
import '../../widgets/import_playlist_dialog.dart';
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

  /// Asks for a YouTube playlist link, then makes a playlist of its songs
  /// and opens it.
  static Future<void> _import(BuildContext context) async {
    final service = context.read<PlaylistService>();
    final choice = await showImportPlaylistDialog(context);
    if (choice == null) return;
    final created = service.createWith(
      choice.name,
      [for (final song in choice.songs) song.toTrack()],
    );
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
        _ActionRow(
          glyph: SwarGlyph.add,
          label: Labels.newPlaylist,
          onTap: () => _create(context),
        ),
        _ActionRow(
          glyph: SwarGlyph.download,
          label: Labels.importFromYoutube,
          onTap: () => _import(context),
        ),
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

/// An action at the top of the list: an icon on a velvet block, in the shape
/// of a playlist row. New playlist, and Import from YouTube.
class _ActionRow extends StatelessWidget {
  final SwarGlyph glyph;
  final String label;
  final VoidCallback onTap;

  const _ActionRow({
    required this.glyph,
    required this.label,
    required this.onTap,
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
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppShape.thumbnail),
                ),
                child: Center(
                  child: SwarIcon(
                    glyph: glyph,
                    size: 22,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
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
