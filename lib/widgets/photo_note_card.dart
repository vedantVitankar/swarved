import 'package:flutter/material.dart';
import '../models/memory.dart';
import '../theme/colors.dart';
import '../theme/shape.dart';
import '../theme/typography.dart';
import '../utils/date_label.dart';
import 'memory_photo.dart';

/// A memory as a small card for the right section: the photo, his words in
/// his handwriting, and the date in gold. Sits straight, never tilted.
class PhotoNoteCard extends StatelessWidget {
  final Memory memory;

  const PhotoNoteCard({super.key, required this.memory});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppShape.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (memory.image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppShape.tile),
              child: MemoryPhoto(memory: memory),
            ),
            const SizedBox(height: 8),
          ],
          if (memory.title.isNotEmpty) ...[
            Text(memory.title, style: AppType.bodyMuted),
            const SizedBox(height: 2),
          ],
          Text(
            memory.caption,
            style: AppType.note.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(longDate(memory.date), style: AppType.goldLabel),
        ],
      ),
    );
  }
}
