import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content/labels.dart';
import '../models/track.dart';
import '../services/player_service.dart';
import '../theme/colors.dart';
import '../theme/shape.dart';
import '../theme/swar_glyphs.dart';
import '../theme/typography.dart';
import 'compact_icon_button.dart';
import 'swar_icon.dart';
import 'track_artwork.dart';

/// Opens the queue in a popup: the song playing, then the songs still to come
/// in this loop, which can be dragged into another order.
Future<void> showQueuePopup(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShape.card),
        side: const BorderSide(color: AppColors.hairline),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 600),
        child: const QueuePopup(),
      ),
    ),
  );
}

/// The inside of the popup. It follows the player: when the song changes or
/// the queue is edited elsewhere, the list changes with it.
class QueuePopup extends StatelessWidget {
  const QueuePopup({super.key});

  @override
  Widget build(BuildContext context) {
    // Only a change to the queue rebuilds this, not every tick of the song.
    return Selector<PlayerService, int>(
      selector: (_, player) => player.queueFingerprint,
      builder: (context, fingerprint, child) {
        final player = context.read<PlayerService>();
        final songs = player.queueFromHere;
        final upcoming = songs.length > 1 ? songs.sublist(1) : <Track>[];

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(
                children: [
                  Expanded(
                      child: Text(Labels.queue, style: AppType.trackTitle)),
                  CompactIconButton(
                    icon: SwarGlyph.close,
                    tooltip: Labels.closePopup,
                    color: AppColors.textSecondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.hairline),
            if (songs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(Labels.queueEmpty, style: AppType.bodyMuted),
              )
            else ...[
              const _SectionLabel(Labels.queueNowPlaying),
              _QueueRow(track: songs.first),
              const _SectionLabel(Labels.queueUpNext),
              if (upcoming.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Text(Labels.queueEmpty, style: AppType.bodyMuted),
                )
              else
                Flexible(
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    buildDefaultDragHandles: false,
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: upcoming.length,
                    // newIndex is already where the song ends up once it has
                    // been lifted out, which is what moveUpcoming expects.
                    onReorderItem: (oldIndex, newIndex) =>
                        player.moveUpcoming(oldIndex, newIndex),
                    itemBuilder: (context, index) => _QueueRow(
                      key: _keyFor(upcoming, index),
                      track: upcoming[index],
                      dragIndex: index,
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  /// A key that stays with the song while it is dragged, even if the same
  /// song happens to be in the queue twice.
  static Key _keyFor(List<Track> songs, int index) {
    final id = songs[index].id;
    var before = 0;
    for (var i = 0; i < index; i++) {
      if (songs[i].id == id) before++;
    }
    return ValueKey('$id#$before');
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(text, style: AppType.goldLabel),
    );
  }
}

/// One song of the queue. The song playing has no handle; every other row has
/// one to drag it by ([dragIndex] is its place in the list).
class _QueueRow extends StatelessWidget {
  final Track track;
  final int? dragIndex;

  const _QueueRow({super.key, required this.track, this.dragIndex});

  @override
  Widget build(BuildContext context) {
    final index = dragIndex;
    final playing = index == null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        children: [
          TrackArtwork(
            bytes: track.artworkBytes,
            url: track.artworkUrl,
            size: 40,
            radius: AppShape.thumbnail,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  track.title,
                  style: AppType.body.copyWith(
                    color: playing ? AppColors.accent : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  track.artist,
                  style: AppType.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (index != null)
            ReorderableDragStartListener(
              index: index,
              child: const MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: SwarIcon(
                    glyph: SwarGlyph.grip,
                    size: 20,
                    color: AppColors.textFaint,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 36),
        ],
      ),
    );
  }
}
