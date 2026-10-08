import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/words.dart';
import '../../models/recap.dart';
import '../../services/content_service.dart';
import '../../services/stats_service.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/typography.dart';
import '../recap/recap_screen.dart';

/// The way into the recap. It stays hidden until the first logged play is
/// old enough, as set in the content file.
class RecapCard extends StatelessWidget {
  const RecapCard({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<StatsService>().entries;
    final afterDays = context.select<ContentService, int>(
        (c) => c.recapSettings.afterDays);

    if (!Recap.isReady(entries, DateTime.now(), afterDays: afterDays)) {
      return const SizedBox.shrink();
    }

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
          onTap: () => RecapScreen.open(context),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Words.recapTitle, style: AppType.sectionLabel),
                  const SizedBox(height: 4),
                  Text(
                    Words.recapBlurb,
                    style: AppType.note.copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
