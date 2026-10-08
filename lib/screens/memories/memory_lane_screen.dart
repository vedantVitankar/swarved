import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/words.dart';
import '../../models/memory.dart';
import '../../services/content_service.dart';
import '../../theme/colors.dart';
import '../../theme/responsive.dart';
import '../../theme/swar_glyphs.dart';
import '../../theme/typography.dart';
import '../../widgets/mini_player_bar.dart';
import '../../widgets/swar_icon.dart';
import 'memory_tile.dart';

/// Memory lane: his photos and words, from the first day to the latest.
class MemoryLaneScreen extends StatelessWidget {
  const MemoryLaneScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MemoryLaneScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memories =
        context.select<ContentService, List<Memory>>((c) => c.memories);

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        backgroundColor: AppColors.base,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const SwarIcon(
            glyph: SwarGlyph.back,
            size: 24,
            color: AppColors.textPrimary,
          ),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      bottomNavigationBar: const MiniPlayerBar(padBottom: true),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: Responsive.contentMaxWidth),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: memories.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Words.memoryLaneTitle, style: AppType.display),
                      const SizedBox(height: 4),
                      Text(Words.memoryLaneBlurb, style: AppType.goldLabel),
                    ],
                  ),
                );
              }
              return MemoryTile(memory: memories[i - 1]);
            },
          ),
        ),
      ),
    );
  }
}
