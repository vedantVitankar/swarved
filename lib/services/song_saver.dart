import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/save_problem.dart';
import '../models/youtube_result.dart';
import '../utils/song_file_name.dart';
import 'saved_songs_index.dart';
import 'secure_token_store.dart';
import 'server_config.dart';
import 'song_writer.dart';

/// How one attempt to save a song ended.
sealed class SaveOutcome {
  const SaveOutcome();
}

/// The song is now a file at [path].
final class SaveDone extends SaveOutcome {
  const SaveDone(this.path);
  final String path;
}

/// The song was saved before, and its file is still there. Nothing was
/// downloaded.
final class SaveAlreadyThere extends SaveOutcome {
  const SaveAlreadyThere(this.path);
  final String path;
}

final class SaveFailed extends SaveOutcome {
  const SaveFailed(this.problem);
  final SaveProblem problem;
}

/// Stops a save part-way with a named reason. Never leaves this file.
class _SaveStop implements Exception {
  const _SaveStop(this.problem);
  final SaveProblem problem;
}

/// Saves a YouTube song as an MP3: asks the server for the converted file,
/// downloads it to a temporary file, then hands it to the [SongWriter].
/// Only runs when the listener asks. Searching and playing never save.
///
/// The token is read fresh each time and only sent to the server. It is
/// never stored or printed here.
class SongSaver {
  SongSaver({
    required ServerConfig config,
    required TokenStore tokenStore,
    required SavedSongsIndex index,
    SongWriter? writer,
    http.Client? client,
    Future<Directory> Function()? tempFolder,
    Duration responseTimeout = const Duration(minutes: 4),
    Duration stallTimeout = const Duration(seconds: 30),
  })  : _config = config,
        _tokenStore = tokenStore,
        _index = index,
        _writer = writer ?? const DirectSongWriter(),
        _client = client ?? http.Client(),
        _tempFolder = tempFolder ?? getTemporaryDirectory,
        _responseTimeout = responseTimeout,
        _stallTimeout = stallTimeout;

  final ServerConfig _config;
  final TokenStore _tokenStore;
  final SavedSongsIndex _index;
  final SongWriter _writer;
  final http.Client _client;
  final Future<Directory> Function() _tempFolder;

  /// The server may have to fetch and convert the song first, which takes
  /// a while before the first byte arrives.
  final Duration _responseTimeout;

  /// How long the download may go quiet before it is given up on.
  final Duration _stallTimeout;

  static const _tempPrefix = 'swarved_save_';
  static const _tempSuffix = '.part';
  static const _staleTempAfter = Duration(minutes: 10);

  /// Songs being saved right now, so tapping twice never downloads twice.
  final Map<String, Future<SaveOutcome>> _running = {};

  /// Saves [song] into [folderPath]. Never throws. [onProgress] gets the
  /// bytes received so far and the total when the server said it. A second
  /// call for a song already being saved shares the first call's result.
  Future<SaveOutcome> save(
    YoutubeResult song, {
    required String folderPath,
    void Function(int received, int? total)? onProgress,
  }) {
    final known = _index.pathFor(song.id);
    if (known != null) return Future.value(SaveAlreadyThere(known));

    return _running.putIfAbsent(song.id, () {
      return _download(song, folderPath, onProgress).whenComplete(() {
        // A block body on purpose: Map.remove hands back this very future,
        // and whenComplete would wait on it forever.
        _running.remove(song.id);
      });
    });
  }

  Future<SaveOutcome> _download(
    YoutubeResult song,
    String folderPath,
    void Function(int received, int? total)? onProgress,
  ) async {
    String? token;
    try {
      token = await _tokenStore.readToken();
    } catch (_) {
      return const SaveFailed(SaveProblem.unexpected);
    }
    if (token == null || token.trim().isEmpty) {
      return const SaveFailed(SaveProblem.noToken);
    }

    final folder = Directory(folderPath);
    if (!await folder.exists()) {
      return const SaveFailed(SaveProblem.folderMissing);
    }

    File? temp;
    try {
      final tempDir = await _tempFolder();
      await _clearOldTemps(tempDir);
      temp = File(p.join(tempDir.path, '$_tempPrefix${song.id}$_tempSuffix'));

      final response = await _open(song, token.trim());
      final total = response.contentLength;
      final received = await _receive(response, temp, total, onProgress);
      if (total != null && received != total) {
        throw const _SaveStop(SaveProblem.connectionLost);
      }
      if (received == 0) throw const _SaveStop(SaveProblem.unexpected);

      final path = await _writer.write(
        source: temp,
        folder: folder,
        fileName: songFileName(song.artist, song.title),
      );
      await _remember(song.id, path);
      return SaveDone(path);
    } on _SaveStop catch (e) {
      return SaveFailed(e.problem);
    } on SongWriteException catch (e) {
      return SaveFailed(e.problem);
    } on FileSystemException catch (e) {
      // Something went wrong with the temporary file. A missing folder
      // would be misleading here: that check was made above.
      final problem = problemForFileError(e);
      return SaveFailed(
        problem == SaveProblem.folderMissing ? SaveProblem.unexpected : problem,
      );
    } catch (e) {
      debugPrint('Could not save ${song.id}: ${e.runtimeType}');
      return const SaveFailed(SaveProblem.unexpected);
    } finally {
      await _deleteQuietly(temp);
    }
  }

  /// Sends the request and returns the response once the server has said
  /// yes. Any other answer stops the save with the matching reason.
  Future<http.StreamedResponse> _open(YoutubeResult song, String token) async {
    final request = http.Request(
      'GET',
      _config.exportUri(
        song.id,
        title: song.title,
        artist: song.artist,
        cover: song.thumbnailUrl,
      ),
    )..headers['X-Token'] = token;

    final http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(_responseTimeout);
    } on TimeoutException {
      throw const _SaveStop(SaveProblem.timeout);
    } on SocketException {
      throw const _SaveStop(SaveProblem.unreachable);
    } on http.ClientException {
      throw const _SaveStop(SaveProblem.unreachable);
    }

    final problem = _problemForStatus(response.statusCode);
    if (problem != null) {
      await _discard(response);
      throw _SaveStop(problem);
    }
    return response;
  }

  /// Writes the response to [temp] and returns how many bytes arrived.
  Future<int> _receive(
    http.StreamedResponse response,
    File temp,
    int? total,
    void Function(int received, int? total)? onProgress,
  ) async {
    final sink = temp.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.stream.timeout(_stallTimeout)) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.flush();
    } catch (e) {
      await _closeQuietly(sink);
      if (e is TimeoutException ||
          e is SocketException ||
          e is HttpException ||
          e is http.ClientException) {
        throw const _SaveStop(SaveProblem.connectionLost);
      }
      rethrow;
    }
    await sink.close();
    return received;
  }

  SaveProblem? _problemForStatus(int status) {
    if (status == 200) return null;
    if (status == 401 || status == 403) return SaveProblem.unauthorized;
    if (status == 404) return SaveProblem.unavailable;
    if (status == 429) return SaveProblem.serverBusy;
    if (status >= 500) return SaveProblem.serverTrouble;
    return SaveProblem.unexpected;
  }

  /// A failed save must not stop the song counting as saved: the file is
  /// there whether or not the index could be updated.
  Future<void> _remember(String videoId, String path) async {
    try {
      await _index.record(videoId, path);
    } catch (e) {
      debugPrint('Could not remember saved song: ${e.runtimeType}');
    }
  }

  /// Removes temporary files left by a save that was killed part-way.
  Future<void> _clearOldTemps(Directory dir) async {
    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        if (!name.startsWith(_tempPrefix) || !name.endsWith(_tempSuffix)) {
          continue;
        }
        final age = DateTime.now().difference(await entity.lastModified());
        if (age >= _staleTempAfter) await _deleteQuietly(entity);
      }
    } catch (_) {
      // Housekeeping only: never let it stop a save.
    }
  }

  Future<void> _discard(http.StreamedResponse response) async {
    try {
      await response.stream.drain<void>().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Tidying up only: nothing to do if it fails.
    }
  }

  Future<void> _closeQuietly(IOSink sink) async {
    try {
      await sink.close();
    } catch (_) {
      // Tidying up only: nothing to do if it fails.
    }
  }

  Future<void> _deleteQuietly(File? file) async {
    if (file == null) return;
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Tidying up only: nothing to do if it fails.
    }
  }
}
