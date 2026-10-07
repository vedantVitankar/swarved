import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/track.dart';
import '../../services/connection_service.dart';
import '../../services/library_service.dart';
import '../../services/player_service.dart';
import '../../services/search_service.dart';
import '../../theme/responsive.dart';
import '../../utils/duplicate_filter.dart';
import '../../utils/local_search.dart';
import 'local_results_section.dart';
import 'search_field.dart';
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

  void _playLocal(List<Track> matches, int index) {
    FocusScope.of(context).unfocus();
    context.read<PlayerService>().playQueue(matches, startIndex: index);
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchService>();
    final library = context.watch<LibraryService>().tracks;
    final hasToken = context.watch<ConnectionService>().hasToken;

    final localMatches = searchLocal(library, search.query);
    final youtube = withoutLocalDuplicates(search.results, library);

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
                    ? const SearchWelcome()
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
                                onPlay: (i) => _playLocal(localMatches, i),
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
