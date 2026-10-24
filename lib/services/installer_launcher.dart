import 'dart:io';

/// Starts a downloaded installer. Returns false when it could not be started.
typedef InstallerLauncher = Future<bool> Function(File installer);

/// What the installer is told: show only its small progress window (no
/// wizard pages), close the running app if it is still open, and never
/// restart Windows. The installer opens SwarVed again when it is done.
const windowsInstallerArguments = [
  '/SILENT',
  '/SP-',
  '/CLOSEAPPLICATIONS',
  '/SUPPRESSMSGBOXES',
  '/NORESTART',
];

/// Runs the installer apart from this app, so it carries on after the app
/// quits. Never throws.
Future<bool> launchWindowsInstaller(File installer) async {
  try {
    await Process.start(
      installer.path,
      windowsInstallerArguments,
      mode: ProcessStartMode.detached,
    );
    return true;
  } catch (_) {
    return false;
  }
}
