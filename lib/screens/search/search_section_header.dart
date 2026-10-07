import 'package:flutter/material.dart';
import '../../theme/typography.dart';

/// The small serif title above a group of results, with an optional line
/// of fine print beneath it.
class SearchSectionHeader extends StatelessWidget {
  final String title;
  final String? caption;

  const SearchSectionHeader({super.key, required this.title, this.caption});

  @override
  Widget build(BuildContext context) {
    final finePrint = caption;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppType.sectionLabel),
          if (finePrint != null) ...[
            const SizedBox(height: 2),
            Text(finePrint, style: AppType.caption),
          ],
        ],
      ),
    );
  }
}
