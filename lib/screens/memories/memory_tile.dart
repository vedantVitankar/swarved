import 'package:flutter/material.dart';
import '../../models/memory.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/typography.dart';
import '../../utils/date_label.dart';
import '../../widgets/sun_mark.dart';

/// One moment: the date in gold, the photo if there is one, then his words
/// in his handwriting.
class MemoryTile extends StatelessWidget {
  final Memory memory;

  const MemoryTile({super.key, required this.memory});

  @override
  Widget build(BuildContext context) {
    final image = memory.image;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(longDate(memory.date), style: AppType.goldLabel),
          const SizedBox(height: 8),
          if (image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppShape.card),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  // Photos are big; decode them near the size they show.
                  cacheWidth: 960,
                  // A missing or misspelled file shows the sun instead of
                  // an error.
                  errorBuilder: (_, __, ___) => const _MissingPhoto(),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            memory.caption,
            style: AppType.note.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _MissingPhoto extends StatelessWidget {
  const _MissingPhoto();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surface,
      child: Center(child: SunMark(size: 64)),
    );
  }
}
