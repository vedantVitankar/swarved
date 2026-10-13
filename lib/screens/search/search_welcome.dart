import 'package:flutter/material.dart';
import '../../content/text_keys.dart';
import '../../content/words.dart';
import '../../models/note_slot.dart';
import '../../theme/typography.dart';
import '../../widgets/content_text.dart';
import '../../widgets/slot_text.dart';
import '../../widgets/sun_mark.dart';

/// What the Search tab shows before anything is typed: the same quiet
/// sun-and-serif composition as the app's other resting screens.
class SearchWelcome extends StatelessWidget {
  const SearchWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 16, 32, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SunMark(size: 64),
            const SizedBox(height: 16),
            ContentText(
              textKey: TextKeys.searchTitle,
              fallback: Words.searchTitle,
              textAlign: TextAlign.center,
              style: AppType.display,
            ),
            const SizedBox(height: 6),
            ContentText(
              textKey: TextKeys.searchSubline,
              fallback: Words.searchSubline,
              textAlign: TextAlign.center,
              style: AppType.goldLabel,
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ContentText(
                    textKey: TextKeys.searchIdle,
                    fallback: Words.searchIdle,
                    textAlign: TextAlign.center,
                    style: AppType.bodyMuted,
                  ),
                  // His handwritten line, only when he has written one.
                  SlotText(
                    slot: NoteSlot.searchNote,
                    style: AppType.note,
                    textAlign: TextAlign.center,
                    topGap: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
