import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content/words.dart';
import '../models/note_line.dart';
import '../models/track.dart';
import '../services/content_service.dart';
import 'note_card.dart';

/// The handwritten card for [track]: its own note if it has one, otherwise
/// one of his general playing notes, otherwise nothing.
class TrackNoteCard extends StatelessWidget {
  final Track track;

  const TrackNoteCard({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    final line = context.select<ContentService, NoteLine?>(
        (content) => content.noteLineFor(track));
    if (line == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: NoteCard(
        label: line.label ?? Words.dedicationLabel,
        note: line.note,
      ),
    );
  }
}
