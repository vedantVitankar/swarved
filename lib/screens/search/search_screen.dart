import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/track.dart';
import '../../services/connection_service.dart';
import '../../services/library_service.dart';
import '../../services/player_service.dart';
import '../../services/search_history_service.dart';
import '../../services/search_service.dart';
import '../../theme/responsive.dart';
import '../../utils/duplicate_filter.dart';
import '../../utils/local_search.dart';
import 'local_results_section.dart';
import 'search_field.dart';
import 'search_history_section.dart';
import 'search_welcome.dart';
import 'youtube_results_section.dart';

/// The Search tab: one bar, your own songs first, then YouTube.
/// Local matches are filtered from the library as you type; YouTube results
/// arrive a moment later. Searching never downloads anything.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Owned here, not in the service, so the typed text survives tab switches
  // (the tabs live in an IndexedStack) and is disposed with the screen.
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear(SearchService search) {
    _controller.clear();
    search.onQueryChanged('');
  }

  /// Plays [tracks] starting at [index], and tucks the keyboard away. The
  /// song she tapped is remembered under Recent searches.
  void _play(List<Track> tracks, int index) {
    FocusScope.of(context).unfocus();
    context.read<SearchHistoryService>().recordPlayed(tracks[index]);
    context.read<PlayerService>().playQueue(tracks, startIndex: index);
  }

  /// A tap on a recent search plays that song alone, and moves it back to
  /// the top of the list.
  void _playRecent(Track track) {
    FocusScope.of(context).unfocus();
    context.read<SearchHistoryService>().recordPlayed(track);
    context.read<PlayerService>().playQueue([track]);
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchService>();
    final library = context.watch<LibraryService>().tracks;
    final hasToken = context.watch<ConnectionService>().hasToken;
    final history = context.watch<SearchHistoryService>();

    final localMatches = searchLocal(library, search.query);
    final youtube = withoutLocalDuplicates(search.results, library);
    final youtubeTracks = [for (final r in youtube) r.toTrack()];

    // The songs shown now are the only ones that can be remembered as added
    // to a playlist from here.
    history.noteShown(
      search.query.isEmpty
          ? const <Track>[]
          : [...localMatches, ...youtubeTracks],
    );

    // The remembered songs that can still be played, newest first.
    final recent = <Track>[
      for (final entry in history.entries)
        if (entry.toTrack(library) case final track?) track,
    ];

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: Responsive.contentMaxWidth,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: SearchField(
                  controller: _controller,
                  onChanged: search.onQueryChanged,
                  onSubmitted: (_) => search.searchNow(),
                  onClear: () => _clear(search),
                ),
              ),
              Expanded(
                child: search.query.isEmpty
                    ? (recent.isEmpty
                        ? const SearchWelcome()
                        : Selector<PlayerService, String?>(
                            selector: (_, player) => player.current?.id,
                            builder: (context, activeId, _) =>
                                SearchHistorySection(
                              tracks: recent,
                              activeId: activeId,
                              onPlay: _playRecent,
                              onRemove: (track) => history.remove(track.id),
                              onClearAll: history.clearAll,
                            ),
                          ))
                    // Only the playing song's id matters here, so position
                    // ticks don't rebuild the results.
                    : Selector<PlayerService, String?>(
                        selector: (_, player) => player.current?.id,
                        builder: (context, activeId, _) {
                          return ListView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.only(bottom: 24),
                            children: [
                              LocalResultsSection(
                                matches: localMatches,
                                activeId: activeId,
                                onPlay: (i) => _play(localMatches, i),
                              ),
                              YoutubeResultsSection(
                                status: search.status,
                                results: youtube,
                                allOwned: search.results.isNotEmpty &&
                                    youtube.isEmpty,
                                query: search.query,
                                hasToken: hasToken,
                                activeId: activeId,
                                onRetry: search.searchNow,
                                onPlay: (i) => _play(youtubeTracks, i),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
