import 'package:flutter/material.dart';
import '../../content/labels.dart';
import '../../content/words.dart';
import '../../models/library_problem.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/typography.dart';
import '../../widgets/sun_mark.dart';

class EmptyLibraryState extends StatelessWidget {
  final VoidCallback onChoose;
  final VoidCallback onOpenSettings;
  final LibraryProblem? problem;

  const EmptyLibraryState({
    super.key,
    required this.onChoose,
    required this.onOpenSettings,
    this.problem,
  });

  static String _bodyFor(LibraryProblem? problem) {
    return switch (problem) {
      null => Words.emptyBody,
      LibraryProblem.noPermission => Words.problemNoPermission,
      LibraryProblem.unreadableFolder => Words.problemUnreadableFolder,
      LibraryProblem.noAudioFound => Words.problemNoAudioFound,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          // The extra bottom padding lifts the group a little above centre,
          // like the preview. Scrolling keeps short desktop windows safe.
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 88),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SunMark(),
              const SizedBox(height: 18),
              Text(Words.emptyTitle,
                  textAlign: TextAlign.center, style: AppType.display),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Text(
                  _bodyFor(problem),
                  textAlign: TextAlign.center,
                  style: AppType.bodyMuted,
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: onChoose,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppShape.button),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  Labels.chooseFolder,
                  style: AppType.bodyMuted.copyWith(color: AppColors.accent),
                ),
              ),
              if (problem == LibraryProblem.noPermission) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onOpenSettings,
                  child: Text(Labels.openSettings, style: AppType.bodyMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
