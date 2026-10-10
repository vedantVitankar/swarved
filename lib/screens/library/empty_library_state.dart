import 'package:flutter/material.dart';
import '../../content/labels.dart';
import '../../content/words.dart';
import '../../models/library_problem.dart';
import '../../theme/typography.dart';
import '../../tutorial/tutorial_controller.dart';
import '../../tutorial/tutorial_step.dart';
import '../../widgets/sun_mark.dart';
import '../../widgets/swar_outlined_button.dart';

/// What the Library tab shows before a music folder is chosen: the sun, a
/// few words, and the way to pick a folder. The rest of the app doesn't wait
/// for one, so this lives inside the tab rather than in front of the app.
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
    };
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SunMark(size: 64),
            const SizedBox(height: 18),
            Text(Words.emptyTitle,
                textAlign: TextAlign.center, style: AppType.display),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(
                _bodyFor(problem),
                textAlign: TextAlign.center,
                style: AppType.bodyMuted,
              ),
            ),
            const SizedBox(height: 18),
            // The tour lights this button up when it asks her to choose.
            KeyedSubtree(
              key: TutorialScope.read(context)?.keyFor(TutorialStep.addFolder),
              child: SwarOutlinedButton(
                label: Labels.chooseFolder,
                onPressed: onChoose,
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
    );
  }
}
