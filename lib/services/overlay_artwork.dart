import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/track.dart';

/// Writes the cover that is inside a song on this computer to a file the
/// media overlay can read, and gives its address. Null when the song has no
/// cover, or the file cannot be written. Never throws.
Future<String?> overlayArtworkFor(Track track) async {
  final bytes = track.artworkBytes;
  if (bytes == null || bytes.isEmpty) return null;
  try {
    final folder = Directory(
      p.join((await getTemporaryDirectory()).path, 'swarved_overlay'),
    );
    await folder.create(recursive: true);
    final name = '${track.id.hashCode.toUnsigned(32).toRadixString(16)}.jpg';
    final file = File(p.join(folder.path, name));
    if (!await file.exists()) await file.writeAsBytes(bytes, flush: true);
    return Uri.file(file.path).toString();
  } catch (error) {
    debugPrint('Cover not written for the overlay: $error');
    return null;
  }
}
