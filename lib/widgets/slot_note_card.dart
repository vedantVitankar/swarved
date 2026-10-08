import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note_line.dart';
import '../models/note_slot.dart';
import '../services/content_service.dart';
import 'note_card.dart';

/// A note card for one [NoteSlot]: one of his notes, or [fallbackNote] when
/// he hasn't written any, or nothing at all when there is no fallback.
/// It brings its own gaps, so a hidden card leaves no empty space behind.
class SlotNoteCard extends StatelessWidget {
  final NoteSlot slot;

  /// The gold label, unless his note names its own.
  final String defaultLabel;
  final String? fallbackNote;
  final double topGap;
  final double bottomGap;

  const SlotNoteCard({
    super.key,
    required this.slot,
    required this.defaultLabel,
    this.fallbackNote,
    this.topGap = 0,
    this.bottomGap = 0,
  });

  @override
  Widget build(BuildContext context) {
    final line = context
        .select<ContentService, NoteLine?>((content) => content.lineFor(slot));
    final note = line?.note ?? fallbackNote;
    if (note == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: topGap, bottom: bottomGap),
      child: NoteCard(label: line?.label ?? defaultLabel, note: note),
    );
  }
}
