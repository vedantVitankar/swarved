import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// The one place album-art rendering (with its empty-state icon) lives.
/// Used by TrackTile, MiniPlayerBar, and NowPlayingScreen.
/// Local songs pass [bytes]; YouTube tracks pass [url].
class TrackArtwork extends StatelessWidget {
  final List<int>? bytes;
  final String? url;
  final double size;
  final double iconSize;
  final double radius;

  const TrackArtwork({
    super.key,
    required this.bytes,
    this.url,
    this.size = 44,
    this.iconSize = 20,
    this.radius = 0,
  });

  Widget get _placeholder =>
      Icon(Icons.album_outlined, color: AppColors.textFaint, size: iconSize);

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;

    return Container(
      width: size,
      height: size,
      clipBehavior: radius > 0 ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border.all(color: AppColors.hairline),
        borderRadius: radius > 0 ? BorderRadius.circular(radius) : null,
      ),
      child: bytes != null
          ? Image.memory(Uint8List.fromList(bytes!), fit: BoxFit.cover)
          : imageUrl != null
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder,
                )
              : _placeholder,
    );
  }
}
