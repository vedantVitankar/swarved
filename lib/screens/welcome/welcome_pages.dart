import 'package:flutter/material.dart';
import '../../content/labels.dart';
import '../../content/words.dart';
import '../../models/note_line.dart';
import '../../models/track.dart';
import '../../services/song_playback.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/swar_glyphs.dart';
import '../../theme/typography.dart';
import '../../widgets/compact_icon_button.dart';
import '../../widgets/stagger_column.dart';
import '../../widgets/swar_icon.dart';

/// The song she is asked to start: a line from him, then a box with the
/// song's title and artist on the left and the play button on the right,
/// then a few words. The song carries on under every step that follows.
///
/// [onPlayed] is told as soon as she presses play, whether or not the song
/// manages to start, so the welcome can let her go on.
class WelcomeSongPage extends StatelessWidget {
  final String line;
  final String text;
  final Track track;
  final SongPlayback playback;
  final VoidCallback? onPlayed;
  final bool instant;

  const WelcomeSongPage({
    super.key,
    required this.line,
    required this.text,
    required this.track,
    required this.playback,
    this.onPlayed,
    this.instant = false,
  });

  @override
  Widget build(BuildContext context) {
    return StaggerColumn(
      instant: instant,
      children: [
        Text(
          line,
          textAlign: TextAlign.center,
          style: AppType.display.copyWith(fontSize: 30),
        ),
        const SizedBox(height: 22),
        _SongBox(track: track, playback: playback, onPlayed: onPlayed),
        const SizedBox(height: 22),
        Text(
          text,
          textAlign: TextAlign.center,
          style: AppType.note.copyWith(
            fontSize: 24,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// The song in its box: title over artist on the left, play on the right.
class _SongBox extends StatelessWidget {
  final Track track;
  final SongPlayback playback;
  final VoidCallback? onPlayed;

  const _SongBox({
    required this.track,
    required this.playback,
    required this.onPlayed,
  });

  @override
  Widget build(BuildContext context) {
    final artist = track.artist;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppShape.card),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  track.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.display.copyWith(fontSize: 22),
                ),
                if (artist.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.note.copyWith(fontSize: 22),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ListenableBuilder(
            listenable: playback,
            builder: (context, _) {
              final playing = playback.isPlaying(track);
              return CompactIconButton(
                icon: playing ? SwarGlyph.pause : SwarGlyph.play,
                tooltip: playing ? Labels.pause : Labels.play,
                boxSize: 56,
                iconSize: 26,
                color: AppColors.onAccent,
                background: AppColors.accent,
                onPressed: () {
                  playback.toggle(track);
                  onPlayed?.call();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Why he made it: a title, a few short paragraphs in his hand, and his
/// signature. The pages below the sun on the welcome journey.
class WelcomeStoryPage extends StatelessWidget {
  final List<String> paragraphs;
  final String signature;
  final bool instant;

  const WelcomeStoryPage({
    super.key,
    required this.paragraphs,
    required this.signature,
    this.instant = false,
  });

  @override
  Widget build(BuildContext context) {
    return StaggerColumn(
      instant: instant,
      children: [
        Text(
          Words.welcomeStoryTitle,
          textAlign: TextAlign.center,
          style: AppType.display.copyWith(fontSize: 30),
        ),
        const SizedBox(height: 18),
        for (final paragraph in paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              paragraph,
              textAlign: TextAlign.center,
              style: AppType.note.copyWith(
                fontSize: 26,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        Text(
          signature,
          textAlign: TextAlign.center,
          style: AppType.note.copyWith(fontSize: 24),
        ),
      ],
    );
  }
}

/// A row of notes she can swipe through, one card at a time.
class WelcomeNotesPage extends StatefulWidget {
  final List<NoteLine> notes;
  final bool instant;

  const WelcomeNotesPage({
    super.key,
    required this.notes,
    this.instant = false,
  });

  @override
  State<WelcomeNotesPage> createState() => _WelcomeNotesPageState();
}

class _WelcomeNotesPageState extends State<WelcomeNotesPage> {
  final PageController _controller = PageController(viewportFraction: 0.84);
  int _index = 0;

  static const double _cardHeight = 230;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Moves to [page], the way a swipe would. With reduced motion it simply
  /// is there. Does nothing past either end.
  void _go(int page) {
    if (page < 0 || page >= widget.notes.length) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(page);
    } else {
      _controller.animateToPage(
        page,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = widget.notes;
    return StaggerColumn(
      instant: widget.instant,
      children: [
        Text(
          Words.welcomeNotesTitle,
          textAlign: TextAlign.center,
          style: AppType.display.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: _cardHeight,
          child: PageView.builder(
            controller: _controller,
            itemCount: notes.length,
            onPageChanged: (page) => setState(() => _index = page),
            itemBuilder: (context, page) =>
                _NoteSlide(note: notes[page], active: page == _index),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NoteArrow(
              label: Labels.welcomeNotePrevious,
              onPressed: _index > 0 ? () => _go(_index - 1) : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '${_index + 1} / ${notes.length}',
                textAlign: TextAlign.center,
                style: AppType.caption,
              ),
            ),
            _NoteArrow(
              label: Labels.welcomeNoteNext,
              pointsRight: true,
              onPressed: _index < notes.length - 1
                  ? () => _go(_index + 1)
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

/// An arrow either side of the note counter, for moving between notes
/// without swiping. Dimmed and dead at the first and last note, where there
/// is nowhere to go.
class _NoteArrow extends StatelessWidget {
  final String label;
  final bool pointsRight;
  final VoidCallback? onPressed;

  const _NoteArrow({
    required this.label,
    required this.onPressed,
    this.pointsRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = SwarIcon(
      glyph: SwarGlyph.back,
      size: 24,
      color: onPressed == null ? AppColors.hairline : AppColors.textSecondary,
    );
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      // The glyph points left; the right-hand arrow is the same one flipped.
      icon: pointsRight ? Transform.flip(flipX: true, child: icon) : icon,
    );
  }
}

/// One card of the carousel. The card in front is full size and bright, the
/// ones beside it are a little smaller and dimmer.
class _NoteSlide extends StatelessWidget {
  final NoteLine note;
  final bool active;

  const _NoteSlide({required this.note, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: active ? 1 : 0.92,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: active ? 1 : 0.5,
        duration: const Duration(milliseconds: 250),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.hairline),
              borderRadius: BorderRadius.circular(AppShape.card),
            ),
            // Scrolls instead of overflowing when the text is long or the
            // system text size is large.
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      note.label ?? Words.welcomeNoteLabel,
                      style: AppType.goldLabel,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      note.note,
                      textAlign: TextAlign.center,
                      style: AppType.note.copyWith(
                        fontSize: 26,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A short tour of the four tabs, and a hint about the notes on songs.
class WelcomeTourPage extends StatelessWidget {
  final bool instant;

  const WelcomeTourPage({super.key, this.instant = false});

  @override
  Widget build(BuildContext context) {
    return StaggerColumn(
      instant: instant,
      children: [
        Text(
          Words.welcomeTourTitle,
          textAlign: TextAlign.center,
          style: AppType.display.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 20),
        const _TourRow(
          glyph: SwarGlyph.home,
          title: Labels.navHome,
          body: Words.tourHome,
        ),
        const _TourRow(
          glyph: SwarGlyph.search,
          title: Labels.navSearch,
          body: Words.tourSearch,
        ),
        const _TourRow(
          glyph: SwarGlyph.shelf,
          title: Labels.navLibrary,
          body: Words.tourLibrary,
        ),
        const _TourRow(
          glyph: SwarGlyph.heart,
          title: Labels.navUs,
          body: Words.tourUs,
        ),
        Text(
          Words.tourClosing,
          textAlign: TextAlign.center,
          style: AppType.note.copyWith(fontSize: 24),
        ),
      ],
    );
  }
}

class _TourRow extends StatelessWidget {
  final SwarGlyph glyph;
  final String title;
  final String body;

  const _TourRow({
    required this.glyph,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.hairline),
            ),
            child: Center(
              child: SwarIcon(
                glyph: glyph,
                size: 22,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppType.titleMedium),
                const SizedBox(height: 2),
                Text(body, style: AppType.bodyMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
