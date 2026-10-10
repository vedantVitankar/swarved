import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_taglib/flutter_taglib.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../content/words.dart';
import '../models/track.dart';
import '../models/tutorial_settings.dart';
import '../models/tutorial_song.dart';

/// What a song's tags say about it.
class SongTags {
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final List<int>? cover;

  const SongTags({
    this.title = '',
    this.artist = '',
    this.album = '',
    this.duration = Duration.zero,
    this.cover,
  });
}

typedef AssetBytes = Future<Uint8List> Function(String asset);
typedef TagReader = SongTags? Function(String path);
typedef CacheDirectory = Future<Directory> Function();

/// Gets the bundled tutorial song ready to play. A song inside the app's
/// assets can't be played directly, so it is copied once into the app's
/// cache folder and played from there like any song on the phone. It needs
/// no library folder and no connection.
///
/// Never throws: if the file isn't in the app (he hasn't added it yet) or
/// can't be copied, the result is null and the tutorial goes on without it.
class TutorialSongService {
  final AssetBytes _loadAsset;
  final TagReader _readTags;
  final CacheDirectory _cacheDirectory;

  TutorialSongService({
    AssetBytes? loadAsset,
    TagReader? readTags,
    CacheDirectory? cacheDirectory,
  })  : _loadAsset = loadAsset ?? _bundledAsset,
        _readTags = readTags ?? _tagsFromFile,
        _cacheDirectory = cacheDirectory ?? getTemporaryDirectory;

  static Future<Uint8List> _bundledAsset(String asset) async {
    final data = await rootBundle.load(asset);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  static SongTags? _tagsFromFile(String path) {
    if (!TagLibFile.isSupported) return null;
    final file = TagLibFile.open(path);
    if (file == null) return null;
    try {
      return SongTags(
        title: file.title,
        artist: file.artist,
        album: file.album,
        duration: file.duration,
        cover: file.hasCover ? file.coverData : null,
      );
    } catch (_) {
      return null;
    } finally {
      file.close();
    }
  }

  Future<TutorialSong?> prepare(TutorialSettings settings) async {
    try {
      final bytes = await _loadAsset(settings.asset);
      final directory = await _cacheDirectory();
      final folder = Directory(p.join(directory.path, 'swarved_welcome'));
      await folder.create(recursive: true);

      final file = File(p.join(folder.path, p.basename(settings.asset)));
      // Copied once; later launches find it there.
      if (!await file.exists() || await file.length() != bytes.length) {
        await file.writeAsBytes(bytes, flush: true);
      }

      final tags = _readTags(file.path);
      final fallbackTitle = p.basenameWithoutExtension(settings.asset);
      final track = Track(
        filePath: file.path,
        title: settings.title ?? _present(tags?.title) ?? fallbackTitle,
        artist: settings.artist ?? _present(tags?.artist) ?? '',
        album: tags?.album ?? '',
        duration: tags?.duration ?? Duration.zero,
        folder: Words.tutorialSongFolder,
        artworkBytes: tags?.cover,
      );
      return TutorialSong(
        track: track,
        label: settings.label,
        note: settings.note,
      );
    } catch (error) {
      debugPrint('Tutorial song not ready: $error');
      return null;
    }
  }

  static String? _present(String? text) {
    final trimmed = text?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
