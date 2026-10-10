import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/tutorial_song.dart';
import '../models/welcome_settings.dart';
import 'tutorial_song_service.dart';

typedef WelcomeLoader = Future<String> Function();

/// Holds what the welcome and the tutorial say and play. They have their own
/// file, assets/welcome/welcome.json, and their own song, and nothing else
/// reads or writes them, so the notes and songs he keeps updating in
/// content.json can never touch the welcome. The file ships inside the app
/// and is read once at startup.
class WelcomeService extends ChangeNotifier {
  final WelcomeLoader _loader;
  final TutorialSongService? _songService;
  WelcomeSettings _settings = const WelcomeSettings();
  TutorialSong? _song;
  Future<void> _songReady = Future.value();

  /// With a [songService] the tutorial's song is prepared in the
  /// background after [load]; with none, there is no tutorial song.
  WelcomeService({WelcomeLoader? loader, TutorialSongService? songService})
      : _loader = loader ?? _bundled,
        _songService = songService;

  static Future<String> _bundled() =>
      rootBundle.loadString('assets/welcome/welcome.json');

  /// What the file says. Every part he left out is null or empty, and the
  /// screen uses its own default for it.
  WelcomeSettings get settings => _settings;

  /// The song the tutorial plays, once it is ready, or null if there is
  /// none (no file, or not ready yet).
  TutorialSong? get tutorialSong => _song;

  /// Completes when the song has been prepared, or found missing.
  Future<void> get songReady => _songReady;

  /// Never throws: a missing or broken file leaves the welcome with its
  /// default words instead of leaving the app without a welcome.
  Future<void> load() async {
    try {
      _settings = WelcomeSettings.parse(jsonDecode(await _loader()));
    } catch (error) {
      debugPrint('Welcome file not loaded: $error');
      _settings = const WelcomeSettings();
    }

    final songService = _songService;
    if (songService == null) return;
    // In the background: the welcome takes a while to get through, so the
    // song is ready long before the tutorial needs it.
    _songReady = songService.prepare(_settings.tutorial).then((song) {
      _song = song;
      notifyListeners();
    });
    unawaited(_songReady);
  }
}
