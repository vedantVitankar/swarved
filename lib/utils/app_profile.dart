import 'package:flutter/foundation.dart';

/// Whose copy of the app this is. There are two, fixed: "swarnima" is hers
/// and "test" is for trying things out, so test data never reaches her.
///
/// Release builds are hers and every other build (debug, profile) is the
/// test one. To override that for one run:
///   flutter run --dart-define=SWARVED_PROFILE=swarnima
abstract final class AppProfile {
  static const String swarnima = 'swarnima';
  static const String test = 'test';

  static const List<String> all = [swarnima, test];

  static const String _override = String.fromEnvironment('SWARVED_PROFILE');

  /// The profile of the running build.
  static String get current =>
      resolve(override: _override, release: kReleaseMode);

  /// The override when it names a real profile, otherwise by build mode.
  /// An unknown override is ignored, never trusted.
  static String resolve({required String override, required bool release}) {
    final wanted = override.trim().toLowerCase();
    if (all.contains(wanted)) return wanted;
    return release ? swarnima : test;
  }
}
