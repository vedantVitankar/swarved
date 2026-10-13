import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/labels.dart';
import '../../models/pushed_playlist.dart';
import '../../services/content_service.dart';
import '../../theme/shape.dart';
import '../../theme/typography.dart';
import '../../widgets/playlist_picture.dart';
import '../../widgets/server_photo.dart';
import '../playlist/playlist_screen.dart';

/// "Made for you": the playlists he made for her, as a row of covers on
/// Home. Brings its own gap above, and nothing at all when he has made none,
/// so Home looks exactly as it did before.
class HomeMadeForYou extends StatelessWidget {
  const HomeMadeForYou({super.key});

  static const double _cover = 132;

  @override
  Widget build(BuildContext context) {
    final lists = context.select<ContentService, List<PushedPlaylist>>(
      (content) => content.pushedPlaylists,
    );
    if (lists.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Labels.madeForYou, style: AppType.sectionLabel),
          const SizedBox(height: 10),
          SizedBox(
            height: _cover + 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: lists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _Card(pushed: lists[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final PushedPlaylist pushed;

  const _Card({required this.pushed});

  @override
  Widget build(BuildContext context) {
    final playlist = pushed.playlist;
    final art = PlaylistPicture(
      playlistId: playlist.id,
      size: HomeMadeForYou._cover,
      radius: AppShape.panel,
    );
    final cover = pushed.coverFile;

    return SizedBox(
      width: HomeMadeForYou._cover,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppShape.panel),
          onTap: () => PlaylistScreen.open(context, playlist.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppShape.panel),
                child: SizedBox(
                  width: HomeMadeForYou._cover,
                  height: HomeMadeForYou._cover,
                  // His chosen cover when he gave one, else the usual
                  // picture made from the songs.
                  child: cover == null
                      ? art
                      : ServerPhoto(
                          name: cover,
                          placeholder: art,
                          cacheWidth: 400,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                playlist.name,
                style: AppType.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
