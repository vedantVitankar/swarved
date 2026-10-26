import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/letter.dart';
import '../../models/memory.dart';
import '../../models/panel_settings.dart';
import '../../models/together.dart';
import '../../services/content_service.dart';
import '../on_this_day_card.dart';
import 'countdown_card.dart';
import 'letters_section.dart';
import 'photo_notes_section.dart';
import 'pinned_note_card.dart';

/// Everything the right-hand section holds, in the order he chose: the pinned
/// note first, then the countdown, "on this day", the letters and the photo
/// notes. Each part brings its own gap below and takes no room when it has
/// nothing to show. Used in the right-hand column on wide windows, and at the
/// bottom of Home on narrow ones.
class PanelBlocks extends StatelessWidget {
  /// Keep only this many of the newest photo notes. Null keeps them all, and
  /// also says so when there are none.
  final int? photoNoteLimit;

  const PanelBlocks({super.key, this.photoNoteLimit});

  @override
  Widget build(BuildContext context) {
    final panel =
        context.select<ContentService, PanelSettings>((c) => c.panel);
    final together =
        context.select<ContentService, Together>((c) => c.together);
    final letters =
        context.select<ContentService, List<Letter>>((c) => c.letters);
    final memories =
        context.select<ContentService, List<Memory>>((c) => c.memories);
    final now = DateTime.now();

    final pinned = panel.pinnedOn(now);
    final days = together.daysUntilMeeting(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pinned != null) PinnedNoteCard(note: pinned),
        for (final block in panel.shown)
          switch (block) {
            PanelBlock.countdown => days == null
                ? const SizedBox.shrink()
                : CountdownCard(label: together.meetingLabel, days: days),
            PanelBlock.onThisDay => const OnThisDayCard(),
            PanelBlock.letters => letters.isEmpty
                ? const SizedBox.shrink()
                : LettersSection(title: panel.lettersTitle, letters: letters),
            PanelBlock.photoNotes => PhotoNotesSection(
                title: panel.photoNotesTitle,
                memories: [
                  for (final memory in memories)
                    if (memory.inPanel) memory,
                ],
                limit: photoNoteLimit,
                saySoWhenEmpty: photoNoteLimit == null,
              ),
          },
      ],
    );
  }
}
