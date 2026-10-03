import 'package:flutter/material.dart';
import '../../models/track.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class FolderLedger extends StatelessWidget {
  final Map<String, List<Track>> byFolder;
  final void Function(String folder, List<Track> tracks) onOpenFolder;

  const FolderLedger({
    super.key,
    required this.byFolder,
    required this.onOpenFolder,
  });

  @override
  Widget build(BuildContext context) {
    final entries = byFolder.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FOLDERS', style: AppType.sectionLabel),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(border: Border.all(color: AppColors.hairline)),
          child: Column(
            children: entries.take(8).map((e) {
              return InkWell(
                onTap: () => onOpenFolder(e.key, e.value),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.hairline),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(e.key,
                            style: AppType.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text('${e.value.length}', style: AppType.readoutAccent),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
