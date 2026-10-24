import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content/words.dart';
import '../models/memory.dart';
import '../services/content_service.dart';
import '../theme/colors.dart';
import '../theme/responsive.dart';
import '../theme/typography.dart';
import 'on_this_day_card.dart';
import 'photo_note_card.dart';

/// The third section on wide windows, a solid column of its own like the
/// navigation rail: "on this day" on top, then her photo notes, newest
/// first, scrolling on their own.
class RightPanel extends StatelessWidget {
  const RightPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final memories =
        context.select<ContentService, List<Memory>>((c) => c.memories);
    final newestFirst = memories.reversed.toList();

    return Container(
      width: Responsive.rightPanelWidth,
      decoration: const BoxDecoration(
        color: AppColors.base,
        border: Border(left: BorderSide(color: AppColors.hairline)),
      ),
      child: SafeArea(
        left: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 22, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OnThisDayCard(),
              Text(Words.photoNotesTitle, style: AppType.sectionLabel),
              const SizedBox(height: 10),
              Expanded(
                child: newestFirst.isEmpty
                    ? Text(Words.photoNotesEmpty, style: AppType.bodyMuted)
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: newestFirst.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, i) =>
                            PhotoNoteCard(memory: newestFirst[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
