import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content/save_words.dart';
import '../models/youtube_result.dart';
import '../services/save_controller.dart';
import '../services/song_saver.dart';
import '../theme/colors.dart';
import '../theme/swar_glyphs.dart';
import 'compact_icon_button.dart';
import 'save_folder_dialog.dart';

/// The button at the end of a YouTube result row: save, saving with progress,
/// saved, or try again. Only rebuilds when this song's own state changes.
class SaveButton extends StatelessWidget {
  final YoutubeResult song;

  /// The size of the icon and of the button around it. Rows use a smaller
  /// button than the mini player does.
  final double iconSize;
  final double boxSize;

  const SaveButton({
    super.key,
    required this.song,
    this.iconSize = 22,
    this.boxSize = 40,
  });

  // A button with no handler would let the tap fall through to the row
  // behind it, and play the song.
  static void _absorbTap() {}

  @override
  Widget build(BuildContext context) {
    return Selector<SaveController, SaveView>(
      selector: (_, controller) => controller.viewOf(song.id),
      builder: (context, view, _) {
        final (stage, percent) = view;
        switch (stage) {
          case SaveStage.saving:
            return Tooltip(
              message: SaveWords.saving,
              child: SizedBox.square(
                dimension: boxSize,
                child: Center(
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                      value: percent == null ? null : percent / 100,
                    ),
                  ),
                ),
              ),
            );
          case SaveStage.saved:
            return CompactIconButton(
              icon: SwarGlyph.saved,
              onPressed: _absorbTap,
              tooltip: SaveWords.saved,
              color: AppColors.accent,
              iconSize: iconSize,
              boxSize: boxSize,
            );
          case SaveStage.failed:
            return CompactIconButton(
              icon: SwarGlyph.refresh,
              onPressed: () => _save(context),
              tooltip: SaveWords.retry,
              color: AppColors.danger,
              iconSize: iconSize,
              boxSize: boxSize,
            );
          case SaveStage.idle:
            return CompactIconButton(
              icon: SwarGlyph.download,
              onPressed: () => _save(context),
              tooltip: SaveWords.save,
              color: AppColors.textSecondary,
              iconSize: iconSize,
              boxSize: boxSize,
            );
        }
      },
    );
  }

  /// Saves the song and says how it went. The messenger is taken before the
  /// wait, because the row may be gone by the time the save finishes: a saved
  /// song moves from the YouTube results into the library results.
  Future<void> _save(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = context.read<SaveController>();

    // The first save has nowhere to go yet: say why, then let her pick.
    if (controller.needsFolder) {
      final go = await showSaveFolderDialog(context);
      if (go != true) return;
    }

    final outcome = await controller.save(song);
    if (outcome == null) return;

    final message = switch (outcome) {
      SaveDone() => SaveWords.done,
      SaveAlreadyThere() => SaveWords.alreadySaved,
      SaveFailed(:final problem) => SaveWords.forProblem(problem),
    };
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
