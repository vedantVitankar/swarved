import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/labels.dart';
import '../../content/words.dart';
import '../../models/note_slot.dart';
import '../../services/stats_service.dart';
import '../../theme/typography.dart';
import '../../widgets/page_body.dart';
import '../../widgets/slot_note_card.dart';
import 'connection_card.dart';
import 'memory_lane_card.dart';
import 'logbook_card.dart';

/// The corner that's just for the two of them. For now: the logbook.
class UsScreen extends StatelessWidget {
  const UsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsService>();

    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Labels.navUs, style: AppType.display),
          const SizedBox(height: 4),
          Text(Words.usSubline, style: AppType.goldLabel),
          const SlotNoteCard(
            slot: NoteSlot.usNote,
            defaultLabel: Words.usNoteLabel,
            topGap: 16,
          ),
          const SizedBox(height: 16),
          LogbookCard(stats: stats),
          // Brings its own gap, and nothing when there are no memories.
          const MemoryLaneCard(),
          const SizedBox(height: 12),
          const ConnectionCard(),
        ],
      ),
    );
  }
}
