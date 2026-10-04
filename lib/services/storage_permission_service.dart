import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// Asks Android for permission to read the listener's audio files.
/// Windows needs no permission, so there this always reports success.
class StoragePermissionService {
  /// True when SwarVed may read local audio.
  ///
  /// Android 13+ uses the audio permission; Android 12 and older use the
  /// storage permission. The one that doesn't exist on a given version is
  /// reported as denied without showing any dialog, so asking for both is
  /// safe and only one of them needs to be granted.
  Future<bool> ensureGranted() async {
    if (!Platform.isAndroid) return true;
    final results = await [Permission.audio, Permission.storage].request();
    return results.values.any((status) => status.isGranted);
  }

  /// Opens SwarVed's page in the system settings, for when Android will
  /// no longer show the permission dialog.
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
