import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/labels.dart';
import '../../content/words.dart';
import '../../models/note_slot.dart';
import '../../services/library_service.dart';
import '../../services/player_service.dart';
import '../../theme/typography.dart';
import '../../tutorial/tutorial_controller.dart';
import '../../tutorial/tutorial_step.dart';
import '../../utils/folder_order.dart';
import '../../widgets/folder_row.dart';
import '../../widgets/page_body.dart';
import '../../widgets/slot_note_card.dart';
import '../../widgets/swar_chips.dart';
import '../../widgets/swar_outlined_button.dart';
import '../folder/folder_screen.dart';
import 'empty_library_state.dart';
import 'library_playlists.dart';

/// The Library tab, in two views: every folder A to Z with the way to choose
/// the music folder, or her playlists with Liked songs first. Without a
/// folder the folders view shows how to pick one. Mixes and notes join
/// later, once the pieces they depend on exist.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const _foldersView = 0;
  static const _playlistsView = 1;
  static const _chipLabels = [Labels.chipFolders, Labels.chipPlaylists];

  int _view = _foldersView;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryService>();
    final folders = sortedFolders(library.byFolder);

    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Labels.libraryTitle, style: AppType.display),
          const SizedBox(height: 12),
          const SlotNoteCard(
            slot: NoteSlot.libraryNote,
            defaultLabel: Words.libraryNoteLabel,
            bottomGap: 12,
          ),
          SwarChips(
            labels: _chipLabels,
            selected: _view,
            onSelected: (i) => setState(() => _view = i),
          ),
          const SizedBox(height: 8),
          if (_view == _playlistsView)
            const LibraryPlaylists()
          else if (library.rootPath == null)
            EmptyLibraryState(
              problem: library.problem,
              onChoose: library.pickAndScanFolder,
              onOpenSettings: library.openPermissionSettings,
            )
          else ...[
            // Only the folder being played from matters here, so position
            // ticks don't rebuild the list.
            Selector<PlayerService, String?>(
              selector: (_, player) => player.current?.folder,
              builder: (context, playingFolder, _) {
                return Column(
                  children: [
                    for (final entry in folders)
                      FolderRow(
                        name: entry.key,
                        songCount: entry.value.length,
                        isPlaying: entry.key == playingFolder,
                        onTap: () => FolderScreen.open(
                          context,
                          title: entry.key,
                          tracks: entry.value,
                        ),
                      ),
                  ],
                );
              },
            ),
            if (folders.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Text(
                  Words.libraryFolderEmpty,
                  style: AppType.bodyMuted,
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              // Lit by the tour when it is made to ask for a folder anyway.
              child: KeyedSubtree(
                key:
                    TutorialScope.read(context)?.keyFor(TutorialStep.addFolder),
                child: SwarOutlinedButton(
                  label: Labels.changeFolder,
                  onPressed: library.pickAndScanFolder,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
