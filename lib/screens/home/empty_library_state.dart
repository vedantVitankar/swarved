import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class EmptyLibraryState extends StatelessWidget {
  final VoidCallback onChoose;
  const EmptyLibraryState({super.key, required this.onChoose});

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: onChoose,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
                child: const Text('Choose folder',
                    style: TextStyle(color: AppColors.accent)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
