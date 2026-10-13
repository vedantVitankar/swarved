import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/labels.dart';
import '../../content/words.dart';
import '../../services/content_service.dart';
import '../../services/media_cache.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/typography.dart';

/// The photos and recordings kept on this phone, and a way to delete them.
/// Photos still in his content download again when they are next shown.
/// Shows nothing when there is nothing kept.
class DownloadsCard extends StatefulWidget {
  const DownloadsCard({super.key});

  @override
  State<DownloadsCard> createState() => _DownloadsCardState();
}

class _DownloadsCardState extends State<DownloadsCard> {
  Future<({int files, int bytes})>? _usage;
  int _seenFiles = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Look again whenever the content changes what it uses.
    final files = Provider.of<ContentService>(context).mediaFiles.length;
    if (_usage == null || files != _seenFiles) {
      _seenFiles = files;
      _usage = context.read<MediaCache>().usage();
    }
  }

  Future<void> _clear() async {
    final cache = context.read<MediaCache>();
    final messenger = ScaffoldMessenger.of(context);
    await cache.clear();
    if (!mounted) return;
    setState(() => _usage = cache.usage());
    messenger.showSnackBar(const SnackBar(content: Text(Words.downloadsCleared)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({int files, int bytes})>(
      future: _usage,
      builder: (context, snapshot) {
        final usage = snapshot.data;
        if (usage == null || usage.files == 0) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.hairline),
              borderRadius: BorderRadius.circular(AppShape.card),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Labels.downloads, style: AppType.sectionLabel),
                      const SizedBox(height: 4),
                      Text(
                        Labels.downloadsSummary(usage.files, usage.bytes),
                        style: AppType.bodyMuted,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _clear,
                  child: Text(Labels.clearDownloads, style: AppType.bodyMuted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
