import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content/labels.dart';
import '../content/words.dart';
import '../models/note_line.dart';
import '../models/track.dart';
import '../services/content_service.dart';
import '../theme/colors.dart';
import '../theme/shape.dart';
import '../theme/swar_glyphs.dart';
import '../theme/typography.dart';
import 'compact_icon_button.dart';
import 'note_card.dart';

/// Opens [track]'s note in a small popup: its own note, or one of his general
/// playing notes, the same words Now Playing shows. Does nothing when the song
/// has neither.
Future<void> showSongNotePopup(BuildContext context, Track track) {
  final line = context.read<ContentService>().noteLineFor(track);
  if (line == null) return Future.value();
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShape.card),
        side: const BorderSide(color: AppColors.hairline),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 520),
        child: SongNotePopup(track: track, line: line),
      ),
    ),
  );
}

/// The inside of the popup: the song, then its note on the handwritten card.
class SongNotePopup extends StatelessWidget {
  final Track track;
  final NoteLine line;

  const SongNotePopup({super.key, required this.track, required this.line});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: AppType.trackTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      track.artist,
                      style: AppType.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              CompactIconButton(
                icon: SwarGlyph.close,
                tooltip: Labels.closePopup,
                color: AppColors.textSecondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: NoteCard(
              label: line.label ?? Words.dedicationLabel,
              note: line.note,
            ),
          ),
        ),
      ],
    );
  }
}
