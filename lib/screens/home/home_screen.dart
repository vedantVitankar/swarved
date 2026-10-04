import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/labels.dart';
import '../../content/words.dart';
import '../../services/library_service.dart';
import '../../theme/typography.dart';
import '../../widgets/note_card.dart';
import '../../widgets/page_body.dart';
import '../../widgets/swar_chips.dart';
import '../library_screen.dart';
import 'empty_library_state.dart';
import 'folder_tile_grid.dart';

enum _HomeFilter { all, folders, notes }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _HomeFilter _filter = _HomeFilter.all;

  static const _chipLabels = [
    Labels.chipAll,
    Labels.chipFolders,
    Labels.chipNotes,
  ];

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryService>();

    if (library.rootPath == null) {
      return EmptyLibraryState(
        problem: library.problem,
        onChoose: library.pickAndScanFolder,
        onOpenSettings: library.openPermissionSettings,
      );
    }

    final showFolders = _filter != _HomeFilter.notes;
    final showNote = _filter != _HomeFilter.folders;

    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Words.greeting(DateTime.now()), style: AppType.display),
          const SizedBox(height: 4),
          Text(Words.homeSubline, style: AppType.goldLabel),
          const SizedBox(height: 12),
          SwarChips(
            labels: _chipLabels,
            selected: _filter.index,
            onSelected: (i) => setState(() => _filter = _HomeFilter.values[i]),
          ),
          if (showFolders) ...[
            const SizedBox(height: 12),
            FolderTileGrid(
              byFolder: library.byFolder,
              onOpenFolder: (folder, tracks) {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => LibraryScreen(title: folder, tracks: tracks),
                ));
              },
            ),
          ],
          if (showNote) ...[
            const SizedBox(height: 14),
            const NoteCard(
              label: Words.noteForYouLabel,
              note: Words.noteForYou,
            ),
          ],
        ],
      ),
    );
  }
}
