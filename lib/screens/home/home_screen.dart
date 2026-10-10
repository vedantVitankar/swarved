import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/labels.dart';
import '../../content/words.dart';
import '../../models/note_slot.dart';
import '../../models/playlist.dart';
import '../../models/track.dart';
import '../../services/library_service.dart';
import '../../services/playlist_service.dart';
import '../../services/stats_service.dart';
import '../../theme/typography.dart';
import '../../tutorial/tutorial_controller.dart';
import '../../tutorial/tutorial_reveal.dart';
import '../../tutorial/tutorial_song_card.dart';
import '../../tutorial/tutorial_step.dart';
import '../../utils/home_tiles.dart';
import '../../utils/recent_folders.dart';
import '../../widgets/page_body.dart';
import '../../widgets/slot_note_card.dart';
import '../../widgets/slot_text.dart';
import '../../widgets/swar_chips.dart';
import '../folder/folder_screen.dart';
import '../playlist/playlist_screen.dart';
import 'home_tile_grid.dart';
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

  /// The Home grid: Liked songs, her newest playlists and the folders she
  /// played last, six in all.
  Widget _tiles(
    LibraryService library,
    List<Playlist> playlists,
    StatsService stats,
  ) {
    final byFolder = library.byFolder;
    final tiles = pickHomeTiles(
      playlists: playlists,
      foldersByRecency: foldersByRecency(
        byFolder,
        stats.entries.map((entry) => entry.trackPath),
      ),
    );
    if (tiles.isEmpty) {
      return Text(Words.homeNoFolders, style: AppType.bodyMuted);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeTileGrid(
          tiles: tiles,
          onOpen: (tile) => _open(tile, byFolder),
        ),
        // Liked songs is always there, so say where folders will gather.
        if (byFolder.isEmpty) ...[
          const SizedBox(height: 10),
          Text(Words.homeNoFolders, style: AppType.bodyMuted),
        ],
      ],
    );
  }

  /// A playlist tile opens its page, a folder tile opens the folder.
  void _open(HomeTile tile, Map<String, List<Track>> byFolder) {
    if (tile.kind == HomeTileKind.playlist) {
      PlaylistScreen.open(context, tile.id);
      return;
    }
    final tracks = byFolder[tile.id];
    if (tracks == null) return;
    FolderScreen.open(context, title: tile.id, tracks: tracks);
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryService>();
    final playlists = context.watch<PlaylistService>().playlists;
    final stats = context.watch<StatsService>();

    final showFolders = _filter != _HomeFilter.notes;
    final showNote = _filter != _HomeFilter.folders;

    // During the first-time intro Home starts blank and fills in. With no
    // intro, tutorial is null or off and everything simply shows.
    final tutorial = TutorialScope.maybeOf(context);
    final greetingShown = tutorial == null || tutorial.greetingVisible;
    final songFirst = tutorial != null && tutorial.songFirst;

    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Laid out from the start so the intro can find its place, but
          // not drawn until the typed greeting has glided into it.
          Opacity(
            opacity: greetingShown ? 1 : 0,
            child: Text(
              Words.greeting(DateTime.now()),
              key: tutorial?.greetingKey,
              style: AppType.display,
            ),
          ),
          const SizedBox(height: 4),
          TutorialReveal(
            order: 0,
            child: SlotText(
              slot: NoteSlot.homeLine,
              fallback: Words.homeSubline,
              style: AppType.goldLabel,
            ),
          ),
          const SizedBox(height: 12),
          TutorialReveal(
            order: 1,
            child: KeyedSubtree(
              key: tutorial?.keyFor(TutorialStep.chips),
              child: SwarChips(
                labels: _chipLabels,
                selected: _filter.index,
                onSelected: (i) =>
                    setState(() => _filter = _HomeFilter.values[i]),
              ),
            ),
          ),
          if (showFolders) ...[
            const SizedBox(height: 12),
            TutorialReveal(
              order: 2,
              child: KeyedSubtree(
                key: tutorial?.keyFor(TutorialStep.folders),
                child: _tiles(library, playlists, stats),
              ),
            ),
          ],
          if (showNote) ...[
            // Brings its own gap above, and nothing when there is no pick.
            // While the tutorial runs the card holds the tutorial's own
            // song, never the song of the day from the content file.
            TutorialReveal(
              part: TutorialPart.song,
              // First when the song comes alone, otherwise in its old place
              // among the blocks.
              order: songFirst ? 0 : 3,
              child: tutorial != null && tutorial.songOnHome
                  ? TutorialSongCard(
                      song: tutorial.song!,
                      cardKey: tutorial.keyFor(TutorialStep.play),
                    )
                  : const HomeSongOfTheDay(),
            ),
            const SizedBox(height: 14),
            // Left out of the intro: it fades in once the intro is over
            // and Home is on screen.
            const TutorialReveal(
              part: TutorialPart.note,
              child: SlotNoteCard(
                slot: NoteSlot.homeNote,
                defaultLabel: Words.noteForYouLabel,
                fallbackNote: Words.noteForYou,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
