import 'package:flutter/material.dart';
import '../../content/words.dart';
import '../../models/memory.dart';
import '../../theme/typography.dart';
import '../photo_note_card.dart';

/// His photo notes, newest first, under a title. [limit] keeps only the
/// newest few, for places with less room. With none to show it says so when
/// [saySoWhenEmpty], and otherwise takes no room.
class PhotoNotesSection extends StatelessWidget {
  /// His own title, or empty for the usual one.
  final String title;
  final List<Memory> memories;
  final int? limit;
  final bool saySoWhenEmpty;

  const PhotoNotesSection({
    super.key,
    required this.title,
    required this.memories,
    this.limit,
    this.saySoWhenEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    final newestFirst = memories.reversed.toList();
    final shown =
        limit == null ? newestFirst : newestFirst.take(limit!).toList();
    if (shown.isEmpty && !saySoWhenEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.isEmpty ? Words.photoNotesTitle : title,
            style: AppType.sectionLabel,
          ),
          const SizedBox(height: 10),
          if (shown.isEmpty)
            Text(Words.photoNotesEmpty, style: AppType.bodyMuted)
          else
            for (final memory in shown) ...[
              PhotoNoteCard(memory: memory),
              const SizedBox(height: 14),
            ],
        ],
      ),
    );
  }
}
