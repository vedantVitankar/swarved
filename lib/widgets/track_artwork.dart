import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// The one place album-art rendering (with its empty-state icon) lives.
/// Used by TrackTile, MiniPlayerBar, and NowPlayingScreen.
class TrackArtwork extends StatelessWidget {
  final List<int>? bytes;
  final double size;
  final double iconSize;

  const TrackArtwork({
    super.key,
    required this.bytes,
    this.size = 44,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border.all(color: AppColors.hairline),
      ),
      child: bytes != null
          ? Image.memory(Uint8List.fromList(bytes!), fit: BoxFit.cover)
          : Icon(Icons.album_outlined,
              color: AppColors.textFaint, size: iconSize),
    );
  }
}
