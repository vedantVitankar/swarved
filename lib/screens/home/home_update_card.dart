import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/labels.dart';
import '../../content/words.dart';
import '../../models/app_release.dart';
import '../../services/update_service.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/typography.dart';
import '../../widgets/swar_outlined_button.dart';

/// On Home, when a newer SwarVed is waiting: one tap downloads it and the app
/// opens again by itself. Shows nothing otherwise.
class HomeUpdateCard extends StatelessWidget {
  const HomeUpdateCard({super.key});

  @override
  Widget build(BuildContext context) {
    final update = context.watch<UpdateService>();
    return UpdateCardView(
      status: update.status,
      release: update.release,
      progress: update.progress,
      onUpdate: update.install,
    );
  }
}

/// What [HomeUpdateCard] shows, from plain values.
class UpdateCardView extends StatelessWidget {
  const UpdateCardView({
    super.key,
    required this.status,
    required this.release,
    required this.progress,
    required this.onUpdate,
  });

  final UpdateStatus status;
  final AppRelease? release;
  final double progress;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final found = release;
    final showing = found != null &&
        (status == UpdateStatus.available ||
            status == UpdateStatus.downloading ||
            status == UpdateStatus.installing ||
            status == UpdateStatus.downloadFailed);
    if (!showing) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.accent),
          borderRadius: BorderRadius.circular(AppShape.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(Words.updateTitle, style: AppType.sectionLabel),
            const SizedBox(height: 4),
            Text(Words.updateBody(found.version), style: AppType.bodyMuted),
            if (found.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(found.notes, style: AppType.note),
            ],
            const SizedBox(height: 12),
            _action(),
          ],
        ),
      ),
    );
  }

  Widget _action() {
    switch (status) {
      case UpdateStatus.downloading:
        return _bar(
          value: progress,
          text: '${Words.updateGetting} ${(progress * 100).round()}%',
        );
      case UpdateStatus.installing:
        return _bar(value: null, text: Words.updateOpening);
      case UpdateStatus.downloadFailed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Words.updateFailed,
              style: AppType.bodyMuted.copyWith(color: AppColors.danger),
            ),
            const SizedBox(height: 8),
            SwarOutlinedButton(
              label: Labels.updateRetry,
              onPressed: onUpdate,
            ),
          ],
        );
      default:
        return SwarOutlinedButton(
          label: Labels.updateNow,
          onPressed: onUpdate,
        );
    }
  }

  Widget _bar({required double? value, required String text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: value,
          color: AppColors.accent,
          backgroundColor: AppColors.hairline,
        ),
        const SizedBox(height: 6),
        Text(text, style: AppType.bodyMuted),
      ],
    );
  }
}
