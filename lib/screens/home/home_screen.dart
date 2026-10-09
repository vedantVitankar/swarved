import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/labels.dart';
import '../../content/words.dart';
import '../../models/note_slot.dart';
import '../../services/library_service.dart';
import '../../theme/typography.dart';
import '../../widgets/page_body.dart';
import '../../widgets/slot_note_card.dart';
import '../../widgets/slot_text.dart';
import '../../widgets/swar_chips.dart';
import '../folder/folder_screen.dart';
import 'folder_tile_grid.dart';
import 'home_song_of_the_day.dart';

enum _HomeFilter { all, folders, notes }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  _HomeFilter _filter = _HomeFilter.all;

  static const _chipLabels = [
    Labels.chipAll,
    Labels.chipFolders,
    Labels.chipNotes,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // The greeting depends on the hour, so refresh it when the app returns.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryService>();

    final showFolders = _filter != _HomeFilter.notes;
    final showNote = _filter != _HomeFilter.folders;

    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Words.greeting(DateTime.now()), style: AppType.display),
          const SizedBox(height: 4),
          SlotText(
            slot: NoteSlot.homeLine,
            fallback: Words.homeSubline,
            style: AppType.goldLabel,
          ),
          const SizedBox(height: 12),
          SwarChips(
            labels: _chipLabels,
            selected: _filter.index,
            onSelected: (i) => setState(() => _filter = _HomeFilter.values[i]),
          ),
          if (showFolders) ...[
            const SizedBox(height: 12),
            if (library.byFolder.isEmpty)
              Text(Words.homeNoFolders, style: AppType.bodyMuted)
            else
              FolderTileGrid(
                byFolder: library.byFolder,
                onOpenFolder: (folder, tracks) => FolderScreen.open(
                  context,
                  title: folder,
                  tracks: tracks,
                ),
              ),
          ],
          if (showNote) ...[
            // Brings its own gap above, and nothing when there is no pick.
            const HomeSongOfTheDay(),
            const SizedBox(height: 14),
            const SlotNoteCard(
              slot: NoteSlot.homeNote,
              defaultLabel: Words.noteForYouLabel,
              fallbackNote: Words.noteForYou,
            ),
          ],
        ],
      ),
    );
  }
}
