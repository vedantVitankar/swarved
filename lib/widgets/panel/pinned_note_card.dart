import 'package:flutter/material.dart';
import '../../content/words.dart';
import '../../models/panel_settings.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/typography.dart';
import '../server_photo.dart';
import '../sun_mark.dart';

/// The note he pinned at the top of the right-hand section: a small gold
/// heading, an optional photo, and his words in his handwriting.
class PinnedNoteCard extends StatelessWidget {
  final PinnedNote note;

  const PinnedNoteCard({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final photo = note.photo;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.accent),
          borderRadius: BorderRadius.circular(AppShape.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.label.isEmpty ? Words.pinnedDefaultLabel : note.label,
              style: AppType.goldLabel,
            ),
            if (photo != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppShape.tile),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ServerPhoto(
                    name: photo,
                    cacheWidth: 960,
                    placeholder: const ColoredBox(
                      color: AppColors.base,
                      child: Center(child: SunMark(size: 64)),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              note.text,
              style: AppType.note.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
