import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/shape.dart';
import '../theme/typography.dart';

/// A small gold label above a line written by hand.
class NoteCard extends StatelessWidget {
  final String label;
  final String note;

  const NoteCard({super.key, required this.label, required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppShape.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppType.goldLabel),
          const SizedBox(height: 2),
          // The preview writes the note itself in cream; only the label is gold.
          Text(note,
              style: AppType.note.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
