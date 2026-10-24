import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/labels.dart';
import '../../services/update_service.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/typography.dart';

/// In Us: which version of the app this is, and a way to look for a newer
/// one. Shows nothing where the app cannot update itself.
class UpdatesCard extends StatelessWidget {
  const UpdatesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final update = context.watch<UpdateService>();
    if (!update.supported) return const SizedBox.shrink();
    return UpdatesCardView(
      version: update.installedVersion?.version,
      status: update.status,
      onCheck: update.check,
    );
  }
}

/// What [UpdatesCard] shows, from plain values.
class UpdatesCardView extends StatelessWidget {
  const UpdatesCardView({
    super.key,
    required this.version,
    required this.status,
    required this.onCheck,
  });

  final String? version;
  final UpdateStatus status;
  final VoidCallback onCheck;

  bool get _busy =>
      status == UpdateStatus.checking ||
      status == UpdateStatus.downloading ||
      status == UpdateStatus.installing;

  String? get _line => switch (status) {
        UpdateStatus.checking => Labels.updateChecking,
        UpdateStatus.upToDate => Labels.updateUpToDate,
        UpdateStatus.checkFailed => Labels.updateCheckFailed,
        UpdateStatus.available ||
        UpdateStatus.downloading ||
        UpdateStatus.installing ||
        UpdateStatus.downloadFailed =>
          Labels.updateWaiting,
        UpdateStatus.idle => null,
      };

  @override
  Widget build(BuildContext context) {
    final line = _line;
    final shownVersion = version;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.hairline),
          borderRadius: BorderRadius.circular(AppShape.card),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Labels.updatesTitle, style: AppType.sectionLabel),
                  if (shownVersion != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      Labels.appVersion(shownVersion),
                      style: AppType.bodyMuted,
                    ),
                  ],
                  if (line != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      line,
                      style: AppType.bodyMuted.copyWith(
                        color: status == UpdateStatus.checkFailed
                            ? AppColors.danger
                            : AppColors.accent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            TextButton(
              onPressed: _busy ? null : onCheck,
              child: Text(Labels.checkForUpdates, style: AppType.bodyMuted),
            ),
          ],
        ),
      ),
    );
  }
}
