import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content/labels.dart';
import '../models/track.dart';
import '../services/content_service.dart';
import '../theme/colors.dart';
import '../theme/swar_glyphs.dart';
import 'compact_icon_button.dart';
import 'queue_popup.dart';
import 'song_note_popup.dart';

/// Opens the playing song's note without leaving the mini player. Dimmed and
/// not pressable when the song has no note, and no general playing note
/// stands in for it.
class NotesButton extends StatelessWidget {
  final Track track;

  const NotesButton({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    final hasNote = context.select<ContentService, bool>(
      (content) => content.noteLineFor(track) != null,
    );
    return Opacity(
      opacity: hasNote ? 1 : 0.4,
      child: CompactIconButton(
        icon: SwarGlyph.notes,
        color: AppColors.textSecondary,
        tooltip: hasNote ? Labels.songNote : Labels.noSongNote,
        onPressed: hasNote ? () => showSongNotePopup(context, track) : null,
      ),
    );
  }
}

/// Opens the queue: the song playing and what comes after it.
class QueueButton extends StatelessWidget {
  const QueueButton({super.key});

  @override
  Widget build(BuildContext context) {
    return CompactIconButton(
      icon: SwarGlyph.queue,
      color: AppColors.textSecondary,
      tooltip: Labels.queue,
      onPressed: () => showQueuePopup(context),
    );
  }
}
