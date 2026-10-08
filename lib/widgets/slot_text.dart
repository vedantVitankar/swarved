import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note_line.dart';
import '../models/note_slot.dart';
import '../services/content_service.dart';

/// One line of text for a [NoteSlot]: one of his notes, or [fallback] when
/// he hasn't written any, or nothing at all when there is no fallback.
class SlotText extends StatelessWidget {
  final NoteSlot slot;
  final String? fallback;
  final TextStyle style;
  final TextAlign? textAlign;

  /// Picks the same note for the same seed. Null means a new note each day.
  final int? seed;
  final double topGap;

  const SlotText({
    super.key,
    required this.slot,
    required this.style,
    this.fallback,
    this.textAlign,
    this.seed,
    this.topGap = 0,
  });

  @override
  Widget build(BuildContext context) {
    final line = context.select<ContentService, NoteLine?>(
        (content) => content.lineFor(slot, seed: seed));
    final text = line?.note ?? fallback;
    if (text == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: Text(text, style: style, textAlign: textAlign),
    );
  }
}
