import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/words.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/typography.dart';
import '../../services/content_service.dart';
import '../memories/memory_lane_screen.dart';

/// The way into memory lane. Hidden until he has written a memory.
class MemoryLaneCard extends StatelessWidget {
  const MemoryLaneCard({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.select<ContentService, int>((c) => c.memories.length);
    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShape.card),
          side: const BorderSide(color: AppColors.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => MemoryLaneScreen.open(context),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Words.memoryLaneTitle, style: AppType.sectionLabel),
                  const SizedBox(height: 4),
                  Text(Words.memoryLaneBlurb, style: AppType.bodyMuted),
                  const SizedBox(height: 8),
                  Text(Words.memoryCount(count), style: AppType.goldLabel),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
