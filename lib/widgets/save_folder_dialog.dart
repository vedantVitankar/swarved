import 'package:flutter/material.dart';
import '../content/labels.dart';
import '../content/save_words.dart';
import '../theme/colors.dart';
import '../theme/shape.dart';
import '../theme/typography.dart';
import 'swar_outlined_button.dart';

/// Asks where saved songs should live, just before the folder picker opens.
/// Answers true to go on and pick a folder, false or null for "not now".
Future<bool?> showSaveFolderDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShape.card),
        side: const BorderSide(color: AppColors.hairline),
      ),
      title: Text(SaveWords.folderPromptTitle, style: AppType.trackTitle),
      content: Text(SaveWords.folderPromptBody, style: AppType.bodyMuted),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(Labels.notNow, style: AppType.bodyMuted),
        ),
        SwarOutlinedButton(
          label: Labels.chooseFolder,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
}
