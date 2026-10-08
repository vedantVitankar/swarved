import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content/words.dart';
import '../models/song_note.dart';
import '../models/track.dart';
import '../services/content_service.dart';
import 'note_card.dart';

/// The handwritten card for [track], or nothing when it has no note.
class TrackNoteCard extends StatelessWidget {
  final Track track;

  const TrackNoteCard({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    final note = context
        .select<ContentService, SongNote?>((content) => content.noteFor(track));
    if (note == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: NoteCard(
        label: note.label ?? Words.dedicationLabel,
        note: note.note,
      ),
    );
  }
}
