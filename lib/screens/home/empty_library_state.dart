import 'package:flutter/material.dart';
import '../../models/library_problem.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

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

  static String _messageFor(LibraryProblem problem) {
    switch (problem) {
      case LibraryProblem.noPermission:
        return 'Let SwarVed see your songs. They never leave this phone.';
      case LibraryProblem.unreadableFolder:
        return "That folder wouldn't open. Let's try another one.";
      case LibraryProblem.noAudioFound:
        return 'No songs here yet. Try the folder where your music lives.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final problem = this.problem;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_open,
                  size: 40, color: AppColors.textFaint),
              const SizedBox(height: 16),
              Text('No archive yet', style: AppType.display),
              const SizedBox(height: 8),
              Text(
                'Point this at a folder of local audio files to build your library.',
                textAlign: TextAlign.center,
                style: AppType.bodyMuted,
              ),
              if (problem != null) ...[
                const SizedBox(height: 16),
                Text(
                  _messageFor(problem),
                  textAlign: TextAlign.center,
                  style: AppType.bodyMuted.copyWith(color: AppColors.accent),
                ),
              ],
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: onChoose,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Choose folder',
                    style: TextStyle(color: AppColors.accent)),
              ),
              if (problem == LibraryProblem.noPermission) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onOpenSettings,
                  child: Text('Open settings', style: AppType.bodyMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
