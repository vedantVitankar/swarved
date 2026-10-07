import 'package:flutter/material.dart';
import '../../content/labels.dart';
import '../../content/words.dart';
import '../../models/youtube_result.dart';
import '../../models/youtube_search_status.dart';
import '../../theme/colors.dart';
import '../../widgets/track_tile.dart';
import 'search_message.dart';
import 'search_section_header.dart';

/// The YouTube half of the results, and every state it can be in:
/// looking, found, nothing found, no token, unreachable, unexpected.
/// For now the rows are shown but not playable; playback comes in Phase 5.
class YoutubeResultsSection extends StatelessWidget {
  final YoutubeSearchStatus status;

  /// Already without the songs the library has.
  final List<YoutubeResult> results;

  /// True when the server found songs but the library already has them all.
  final bool allOwned;

  final String query;

  /// Whether a token is saved, to tell "no token" from "wrong token".
  final bool hasToken;

  final String? activeId;
  final VoidCallback onRetry;

  const YoutubeResultsSection({
    super.key,
    required this.status,
    required this.results,
    required this.allOwned,
    required this.query,
    required this.hasToken,
    required this.activeId,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchSectionHeader(
          title: Words.searchYoutubeHeader,
          caption: results.isEmpty ? null : Words.youtubePlaySoon,
        ),
        if (status == YoutubeSearchStatus.loading) const _LoadingLine(),
        ..._body(),
      ],
    );
  }

  List<Widget> _body() {
    if (results.isNotEmpty) {
      return [
        for (final result in results) _tile(result),
      ];
    }

    return switch (status) {
      YoutubeSearchStatus.idle => const [],
      YoutubeSearchStatus.loading => const [
          SearchMessage(text: Words.searching),
        ],
      YoutubeSearchStatus.loaded => [
          SearchMessage(
            text: allOwned
                ? Words.searchAllOwned
                : Words.searchNothingFor(query),
          ),
        ],
      YoutubeSearchStatus.unauthorized => [
          SearchMessage(
            text: hasToken ? Words.searchBadToken : Words.searchNoToken,
          ),
        ],
      YoutubeSearchStatus.unreachable => [
          SearchMessage(
            text: Words.searchUnreachable,
            actionLabel: Labels.tryAgain,
            onAction: onRetry,
          ),
        ],
      YoutubeSearchStatus.unexpected => [
          SearchMessage(
            text: Words.searchUnexpected,
            actionLabel: Labels.tryAgain,
            onAction: onRetry,
          ),
        ],
    };
  }

  Widget _tile(YoutubeResult result) {
    final track = result.toTrack();
    return TrackTile(
      track: track,
      isActive: activeId == track.id,
      onTap: null,
    );
  }
}

/// A thin rose line that shows the search is still looking.
class _LoadingLine extends StatelessWidget {
  const _LoadingLine();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: LinearProgressIndicator(
        minHeight: 2,
        color: AppColors.accent,
        backgroundColor: AppColors.hairline,
        semanticsLabel: Words.searching,
      ),
    );
  }
}
