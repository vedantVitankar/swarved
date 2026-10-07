import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../utils/artwork_url.dart';

/// The one place album-art rendering (with its empty-state icon) lives.
/// Used by TrackTile, MiniPlayerBar, and NowPlayingScreen.
/// Local songs pass [bytes]; YouTube tracks pass [url].
class TrackArtwork extends StatelessWidget {
  final List<int>? bytes;
  final String? url;

  /// For big artwork only: asks for a picture about this many pixels wide
  /// instead of the small thumbnail in [url]. If that picture can't be
  /// loaded, the original [url] is used, so the artwork never goes missing.
  final int? sharpPixels;
  final double size;
  final double iconSize;
  final double radius;

  const TrackArtwork({
    super.key,
    required this.bytes,
    this.url,
    this.sharpPixels,
    this.size = 44,
    this.iconSize = 20,
    this.radius = 0,
  });

  Widget get _placeholder =>
      Icon(Icons.album_outlined, color: AppColors.textFaint, size: iconSize);

  Widget _network(String original) {
    final wanted = sharpPixels;
    final sharp =
        wanted == null ? original : resizedArtworkUrl(original, wanted);

    return Image.network(
      sharp,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => sharp == original
          ? _placeholder
          : Image.network(
              original,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder,
            ),
    );
  }

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
              ? _network(imageUrl)
              : _placeholder,
    );
  }
}
