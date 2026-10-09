import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/welcome_settings.dart';

typedef WelcomeLoader = Future<String> Function();

/// Holds what the welcome screen says.
///
/// It has its own file, assets/welcome/welcome.json, and nothing else reads
/// or writes it. The notes and songs that content.json keeps getting (and
/// that will later be pushed from the web page) can therefore never touch
/// the welcome. The file ships inside the app and is read once at startup;
/// it is not a ChangeNotifier because it never changes while the app runs.
class WelcomeService {
  final WelcomeLoader _loader;
  WelcomeSettings _settings = const WelcomeSettings();

  WelcomeService({WelcomeLoader? loader}) : _loader = loader ?? _bundled;

  static Future<String> _bundled() =>
      rootBundle.loadString('assets/welcome/welcome.json');

  /// What the file says. Every part he left out is null or empty, and the
  /// screen uses its own default words for it.
  WelcomeSettings get settings => _settings;

  /// Never throws: a missing or broken file leaves the welcome with its
  /// default words instead of leaving the app without a welcome.
  Future<void> load() async {
    try {
      _settings = WelcomeSettings.parse(jsonDecode(await _loader()));
    } catch (error) {
      debugPrint('Welcome file not loaded: $error');
      _settings = const WelcomeSettings();
    }
  }
}
