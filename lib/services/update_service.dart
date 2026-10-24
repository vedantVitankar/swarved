import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/app_release.dart';
import 'app_version.dart';
import 'installer_launcher.dart';
import 'secure_token_store.dart';
import 'server_config.dart';

enum UpdateStatus {
  /// Nothing asked yet.
  idle,
  checking,
  upToDate,
  checkFailed,

  /// A newer release is on the server.
  available,
  downloading,

  /// The installer is verified and has been started.
  installing,
  downloadFailed,
}

typedef UpdateFolder = Future<Directory> Function();

/// Asks the server whether a newer release of the app exists, and installs
/// it: downloads the installer, checks it is exactly what the server
/// published, starts it and quits so the installer can replace the files.
///
/// Nothing here ever throws or blocks the music: every failure is a status.
class UpdateService extends ChangeNotifier {
  UpdateService({
    required ServerConfig config,
    required TokenStore tokenStore,
    required Future<AppVersion?> Function() installed,
    this.supported = true,
    String platform = 'windows',
    InstallerLauncher launch = launchWindowsInstaller,
    void Function()? quit,
    http.Client? client,
    UpdateFolder? folder,
  })  : _config = config,
        _tokenStore = tokenStore,
        _installed = installed,
        _platform = platform,
        _launch = launch,
        _quit = quit ?? _exitApp,
        _client = client ?? http.Client(),
        _folder = folder ?? getTemporaryDirectory;

  static void _exitApp() => exit(0);

  static const _checkTimeout = Duration(seconds: 10);
  static const _connectTimeout = Duration(seconds: 30);

  /// An installer is tens of megabytes, so a download may take a while, but
  /// it must keep moving.
  static const _stallTimeout = Duration(seconds: 30);

  /// False where there is no installer to run (every platform but Windows
  /// for now). Then nothing is ever asked or shown.
  final bool supported;

  final ServerConfig _config;
  final TokenStore _tokenStore;
  final Future<AppVersion?> Function() _installed;
  final String _platform;
  final InstallerLauncher _launch;
  final void Function() _quit;
  final http.Client _client;
  final UpdateFolder _folder;

  UpdateStatus _status = UpdateStatus.idle;
  AppRelease? _release;
  AppVersion? _installedVersion;
  double _progress = 0;
  bool _disposed = false;

  UpdateStatus get status => _status;

  /// The newer release, while there is one to install.
  AppRelease? get release => _release;

  /// The version running now, once it has been read.
  AppVersion? get installedVersion => _installedVersion;

  /// How much of the installer is here, from 0 to 1.
  double get progress => _progress;

  bool get busy =>
      _status == UpdateStatus.checking ||
      _status == UpdateStatus.downloading ||
      _status == UpdateStatus.installing;

  void _set(UpdateStatus status) {
    _status = status;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Asks the server for the newest release and compares it with this one.
  Future<void> check() async {
    if (!supported || busy) return;
    _set(UpdateStatus.checking);
    try {
      final now = await _installed();
      if (now == null) {
        _set(UpdateStatus.checkFailed);
        return;
      }
      _installedVersion = now;

      final token = await _tokenStore.readToken();
      if (token == null || token.trim().isEmpty) {
        _set(UpdateStatus.checkFailed);
        return;
      }

      final response = await _client.get(
        _config.appUpdateUri(_platform),
        headers: {'X-Token': token},
      ).timeout(_checkTimeout);

      if (response.statusCode == 204) {
        _upToDate();
        return;
      }
      if (response.statusCode != 200) {
        _set(UpdateStatus.checkFailed);
        return;
      }
      final found = AppRelease.tryParse(jsonDecode(response.body));
      if (found == null) {
        _set(UpdateStatus.checkFailed);
        return;
      }
      if (found.build > now.build) {
        _release = found;
        _set(UpdateStatus.available);
      } else {
        _upToDate();
      }
    } catch (error) {
      debugPrint('Update check failed: $error');
      _set(UpdateStatus.checkFailed);
    }
  }

  void _upToDate() {
    _release = null;
    _set(UpdateStatus.upToDate);
    // Whatever was downloaded for the update that just finished is no use.
    unawaited(_deleteDownloads());
  }

  /// Downloads the release found by [check], verifies it, starts the
  /// installer and quits the app. Does nothing unless a release is waiting
  /// (or the last try failed).
  Future<void> install() async {
    final target = _release;
    if (!supported || target == null) return;
    if (_status != UpdateStatus.available &&
        _status != UpdateStatus.downloadFailed) {
      return;
    }
    _progress = 0;
    _set(UpdateStatus.downloading);

    File? part;
    try {
      final token = await _tokenStore.readToken();
      if (token == null || token.trim().isEmpty) {
        throw const _InstallFailure('no token');
      }

      final folder = await _freshFolder();
      final file = File(p.join(folder.path, target.file));
      part = File('${file.path}.part');

      final request = http.Request(
        'GET',
        _config.appUpdateFileUri(target.file),
      )..headers['X-Token'] = token;
      final response = await _client.send(request).timeout(_connectTimeout);
      if (response.statusCode != 200) {
        await response.stream.listen((_) {}).cancel();
        throw _InstallFailure('server said ${response.statusCode}');
      }

      var received = 0;
      final sink = part.openWrite();
      try {
        await for (final chunk in response.stream.timeout(_stallTimeout)) {
          sink.add(chunk);
          received += chunk.length;
          _moveTo(received / target.size);
        }
      } finally {
        await sink.close();
      }

      if (received != target.size) {
        throw _InstallFailure('got $received of ${target.size} bytes');
      }
      final digest = await sha256.bind(part.openRead()).first;
      if (digest.toString() != target.sha256) {
        throw const _InstallFailure('checksum does not match');
      }

      // A file with its real name is always a whole, checked one.
      await part.rename(file.path);
      _set(UpdateStatus.installing);

      if (!await _launch(file)) {
        throw const _InstallFailure('installer did not start');
      }
      _quit();
    } catch (error) {
      debugPrint('Update not installed: $error');
      await _discard(part);
      _set(UpdateStatus.downloadFailed);
    }
  }

  /// Only tells listeners about whole percents, so a download does not
  /// redraw the card for every chunk.
  void _moveTo(double fraction) {
    final next = fraction.clamp(0.0, 1.0);
    if (next - _progress >= 0.01 || (next == 1 && _progress != 1)) {
      _progress = next;
      if (!_disposed) notifyListeners();
    }
  }

  Future<Directory> _downloads() async {
    final base = await _folder();
    return Directory(p.join(base.path, 'swarved_update'));
  }

  /// An empty download folder, so old installers never pile up.
  Future<Directory> _freshFolder() async {
    final folder = await _downloads();
    if (await folder.exists()) await folder.delete(recursive: true);
    await folder.create(recursive: true);
    return folder;
  }

  Future<void> _deleteDownloads() async {
    try {
      final folder = await _downloads();
      if (await folder.exists()) await folder.delete(recursive: true);
    } catch (error) {
      debugPrint('Old update files not removed: $error');
    }
  }

  Future<void> _discard(File? part) async {
    try {
      if (part != null && await part.exists()) await part.delete();
    } catch (_) {}
  }
}

class _InstallFailure implements Exception {
  const _InstallFailure(this.reason);
  final String reason;

  @override
  String toString() => reason;
}
