import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/labels.dart';
import '../../content/words.dart';
import '../../models/playlist.dart';
import '../../services/playlist_service.dart';
import '../../theme/colors.dart';
import '../../theme/swar_glyphs.dart';
import '../../theme/typography.dart';
import '../../widgets/playlist_name_dialog.dart';
import '../../widgets/swar_icon.dart';

enum _Choice { rename, delete }

/// The three dots on a playlist's page: rename it, or delete it. Deleting
/// leaves the page and offers Undo, which brings the playlist back with its
/// songs. Only for playlists she made.
class PlaylistMenu extends StatelessWidget {
  final Playlist playlist;

  const PlaylistMenu({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_Choice>(
      tooltip: Labels.playlistOptions,
      color: AppColors.surfaceRaised,
      icon: const SwarIcon(
        glyph: SwarGlyph.more,
        size: 24,
        color: AppColors.textPrimary,
      ),
      onSelected: (choice) {
        switch (choice) {
          case _Choice.rename:
            _rename(context);
          case _Choice.delete:
            _delete(context);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _Choice.rename,
          child: Text(Labels.rename, style: AppType.body),
        ),
        PopupMenuItem(
          value: _Choice.delete,
          child: Text(
            Labels.delete,
            style: AppType.body.copyWith(color: AppColors.danger),
          ),
        ),
      ],
    );
  }

  Future<void> _rename(BuildContext context) async {
    final service = context.read<PlaylistService>();
    final name = await showPlaylistNameDialog(
      context,
      title: Labels.renamePlaylist,
      confirmLabel: Labels.save,
      initialName: playlist.name,
    );
    if (name != null) service.rename(playlist.id, name);
  }

  void _delete(BuildContext context) {
    final service = context.read<PlaylistService>();
    final messenger = ScaffoldMessenger.of(context);
    final id = playlist.id;
    if (!service.delete(id)) return;
    Navigator.of(context).maybePop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(Words.playlistDeleted(playlist.name)),
        action: SnackBarAction(
          label: Labels.undo,
          onPressed: () => service.restore(id),
        ),
      ),
    );
  }
}
