import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/labels.dart';
import '../../content/words.dart';
import '../../models/note_slot.dart';
import '../../services/library_service.dart';
import '../../services/player_service.dart';
import '../../theme/typography.dart';
import '../../utils/folder_order.dart';
import '../../widgets/folder_row.dart';
import '../../widgets/page_body.dart';
import '../../widgets/slot_note_card.dart';
import '../../widgets/swar_outlined_button.dart';
import '../folder/folder_screen.dart';
import 'empty_library_state.dart';

/// The Library tab: every folder, A to Z, and the way to choose the music
/// folder. Without a folder it shows how to pick one. Mixes, notes and
/// pinned items join later, once the pieces they depend on exist.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

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
          if (library.rootPath == null)
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
              child: SwarOutlinedButton(
                label: Labels.changeFolder,
                onPressed: library.pickAndScanFolder,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
