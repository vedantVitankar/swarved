import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../services/player_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/track_tile.dart';

class LibraryScreen extends StatelessWidget {
  final String title;
  final List<Track> tracks;

  const LibraryScreen({super.key, required this.title, required this.tracks});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        backgroundColor: AppColors.base,
        elevation: 0,
        title: Text(title.toUpperCase(), style: AppType.sectionLabel),
      ),
      body: ListView.builder(
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          return TrackTile(
            track: track,
            isActive: player.current?.filePath == track.filePath,
            onTap: () => player.playQueue(tracks, startIndex: index),
          );
        },
      ),
    );
  }
}
