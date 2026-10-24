import 'package:flutter/material.dart';
import '../models/memory.dart';
import '../theme/colors.dart';
import 'server_photo.dart';
import 'sun_mark.dart';

/// A memory's picture, four by three: from the server (fetched once, then
/// kept on this device) or from the app's own assets. Shows the sun when the
/// picture is missing. Nothing at all for a memory without a picture.
class MemoryPhoto extends StatelessWidget {
  final Memory memory;

  const MemoryPhoto({super.key, required this.memory});

  @override
  Widget build(BuildContext context) {
    final image = memory.image;
    if (image == null) return const SizedBox.shrink();

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: memory.hasServerPhoto
          ? ServerPhoto(
              name: image,
              placeholder: const _MissingPhoto(),
              cacheWidth: 960,
            )
          : Image.asset(
              image,
              fit: BoxFit.cover,
              // Photos are big; decode them near the size they show.
              cacheWidth: 960,
              // A missing or misspelled file shows the sun instead of an
              // error.
              errorBuilder: (_, __, ___) => const _MissingPhoto(),
            ),
    );
  }
}

class _MissingPhoto extends StatelessWidget {
  const _MissingPhoto();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surface,
      child: Center(child: SunMark(size: 64)),
    );
  }
}
