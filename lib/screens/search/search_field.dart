import 'package:flutter/material.dart';
import '../../content/labels.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/typography.dart';
import '../../widgets/compact_icon_button.dart';

/// The one search bar. A clear button appears once something is typed.
/// The screen owns [controller], so the text survives switching tabs.
class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppShape.panel),
        borderSide: BorderSide(color: color),
      );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      style: AppType.body,
      cursorColor: AppColors.accent,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        hintText: Labels.searchHint,
        hintStyle: AppType.bodyMuted,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        prefixIcon: const Icon(
          Icons.search,
          size: 20,
          color: AppColors.textFaint,
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 44, minHeight: 40),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return CompactIconButton(
              icon: Icons.close,
              iconSize: 18,
              boxSize: 36,
              color: AppColors.textSecondary,
              tooltip: Labels.clearSearch,
              onPressed: onClear,
            );
          },
        ),
        suffixIconConstraints:
            const BoxConstraints(minWidth: 40, minHeight: 40),
        enabledBorder: _border(AppColors.hairline),
        focusedBorder: _border(AppColors.accent),
      ),
    );
  }
}
