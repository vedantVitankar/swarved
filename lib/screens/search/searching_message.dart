import 'package:flutter/material.dart';
import '../../content/words.dart';
import '../../models/note_slot.dart';
import '../../theme/typography.dart';
import '../../utils/daily_pick.dart';
import '../../widgets/slot_text.dart';

/// The line shown while YouTube is being searched: one of his "loading"
/// notes, or the plain default. The same search always gets the same line,
/// so it doesn't flicker while the results are on their way.
class SearchingMessage extends StatelessWidget {
  final String query;

  const SearchingMessage({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SlotText(
        slot: NoteSlot.loading,
        fallback: Words.searching,
        style: AppType.bodyMuted,
        seed: seedFromText(query),
      ),
    );
  }
}
