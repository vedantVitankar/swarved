import 'package:package_info_plus/package_info_plus.dart';

/// The version this copy of the app was built as: [version] like 1.0.1 for
/// people, [build] (the number after the + in pubspec.yaml) for comparing.
typedef AppVersion = ({String version, int build});

/// What is installed right now, or null when Windows does not say (a build
/// number that is missing or not a number). Never throws.
Future<AppVersion?> readInstalledVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    final build = int.tryParse(info.buildNumber.trim());
    if (build == null || build <= 0) return null;
    return (version: info.version, build: build);
  } catch (_) {
    return null;
  }
}
