import 'package:flutter/material.dart';
import '../content/labels.dart';
import '../models/playlist.dart';
import '../theme/colors.dart';
import '../theme/shape.dart';
import '../theme/typography.dart';

/// Asks for a playlist's name, to make one or to rename one. Answers the
/// name as it will be kept (see [Playlist.cleanName]), or null when she
/// cancels. The confirm button stays off while the name is empty.
Future<String?> showPlaylistNameDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initialName = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NameDialog(
      title: title,
      confirmLabel: confirmLabel,
      initialName: initialName,
    ),
  );
}

class _NameDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final String initialName;

  const _NameDialog({
    required this.title,
    required this.confirmLabel,
    required this.initialName,
  });

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _name => Playlist.cleanName(_controller.text);

  void _submit() {
    final name = _name;
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShape.card),
        side: const BorderSide(color: AppColors.hairline),
      ),
      title: Text(widget.title, style: AppType.trackTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: Playlist.maxNameLength,
        textCapitalization: TextCapitalization.sentences,
        style: AppType.body,
        cursorColor: AppColors.accent,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: Labels.playlistNameHint,
          hintStyle: AppType.bodyMuted,
          counterText: '',
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.hairline),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.accent),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            Labels.cancel,
            style: AppType.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: _name.isEmpty ? null : _submit,
          child: Text(
            widget.confirmLabel,
            style: AppType.body.copyWith(
              color: _name.isEmpty ? AppColors.textFaint : AppColors.accent,
            ),
          ),
        ),
      ],
    );
  }
}
