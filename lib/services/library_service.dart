import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_taglib/flutter_taglib.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import '../models/library_problem.dart';
import 'storage_permission_service.dart';

const _kLibraryPathKey = 'library_root_path';
const _kAudioExtensions = {'.mp3', '.m4a', '.flac', '.wav', '.ogg', '.aac'};

/// Scans a user-chosen local directory and builds the in-memory library.
/// Nothing here ever touches the network — every track is a file already
/// on disk. Tag reading uses flutter_taglib (TagLib via Native Assets),
/// which avoids the CMake/symlink extraction bug that blocked audiotags
/// on Windows.
class LibraryService extends ChangeNotifier {
  LibraryService({StoragePermissionService? permission})
      : _permission = permission ?? StoragePermissionService();

  final StoragePermissionService _permission;

  String? rootPath;
  List<Track> tracks = [];
  bool isScanning = false;

  /// Why the last attempt to open a library failed; null when all is well.
  LibraryProblem? problem;

  /// Tracks grouped by their immediate parent folder name, for the
  /// folder tiles on the home screen.
  Map<String, List<Track>> get byFolder {
    final map = <String, List<Track>>{};
    for (final t in tracks) {
      map.putIfAbsent(t.folder, () => []).add(t);
    }
    return map;
  }

  Future<void> restoreLastLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLibraryPathKey);
    if (saved != null && Directory(saved).existsSync()) {
      await scanFolder(saved);
    }
  }

  Future<void> pickAndScanFolder() async {
    if (!await _permission.ensureGranted()) {
      problem = LibraryProblem.noPermission;
      notifyListeners();
      return;
    }
    problem = null;
    notifyListeners();

    final selected = await FilePicker.getDirectoryPath();
    if (selected == null) return;
    await scanFolder(selected);
    if (problem == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLibraryPathKey, selected);
    }
  }

  Future<void> openPermissionSettings() => _permission.openSettings();

  Future<void> scanFolder(String path) async {
    isScanning = true;
    problem = null;
    rootPath = path;
    notifyListeners();

    final found = <Track>[];
    final dir = Directory(path);
    if (await dir.exists()) {
      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final ext = p.extension(entity.path).toLowerCase();
        if (!_kAudioExtensions.contains(ext)) continue;

        found.add(_readTrack(entity));
      }
    }

    found.sort((a, b) => a.title.compareTo(b.title));
    tracks = found;
    isScanning = false;
    if (found.isEmpty) {
      problem = await dir.exists()
          ? LibraryProblem.noAudioFound
          : LibraryProblem.unreadableFolder;
      rootPath = null;
    }
    notifyListeners();
  }

  Track _readTrack(File file) {
    final folderName = p.basename(p.dirname(file.path));
    final fallbackTitle = p.basenameWithoutExtension(file.path);

    if (!TagLibFile.isSupported) {
      return Track(
        filePath: file.path,
        title: fallbackTitle,
        artist: 'Unknown artist',
        album: folderName,
        duration: Duration.zero,
        folder: folderName,
        artworkBytes: null,
      );
    }

    final tagFile = TagLibFile.open(file.path);
    if (tagFile == null) {
      return Track(
        filePath: file.path,
        title: fallbackTitle,
        artist: 'Unknown artist',
        album: folderName,
        duration: Duration.zero,
        folder: folderName,
        artworkBytes: null,
      );
    }

    try {
      return Track(
        filePath: file.path,
        title: tagFile.title.isNotEmpty ? tagFile.title : fallbackTitle,
        artist: tagFile.artist.isNotEmpty ? tagFile.artist : 'Unknown artist',
        album: tagFile.album.isNotEmpty ? tagFile.album : folderName,
        duration: tagFile.duration,
        folder: folderName,
        artworkBytes: tagFile.hasCover ? tagFile.coverData : null,
      );
    } catch (_) {
      return Track(
        filePath: file.path,
        title: fallbackTitle,
        artist: 'Unknown artist',
        album: folderName,
        duration: Duration.zero,
        folder: folderName,
        artworkBytes: null,
      );
    } finally {
      tagFile.close();
    }
  }
}
