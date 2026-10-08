import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/content_pack.dart';
import '../models/song_note.dart';
import '../models/song_of_the_day.dart';
import '../models/track.dart';

typedef ContentLoader = Future<String> Function();

/// Holds what he has written for her. Today the content file ships inside
/// the app; later the server fills it. Only [loader] changes then.
class ContentService extends ChangeNotifier {
  final ContentLoader _loader;
  ContentPack _pack = ContentPack.empty;

  ContentService({ContentLoader? loader}) : _loader = loader ?? _bundled;

  static Future<String> _bundled() =>
      rootBundle.loadString('assets/content/content.json');

  ContentPack get pack => _pack;

  /// Never throws: a missing or broken file leaves the app without notes
  /// instead of without music.
  Future<void> load() async {
    try {
      _pack = ContentPack.parse(await _loader());
    } catch (error) {
      debugPrint('Content file not loaded: $error');
      _pack = ContentPack.empty;
    }
    notifyListeners();
  }

  SongNote? noteFor(Track track) => _pack.noteFor(track);

  /// The song he picked for today, or null.
  SongOfTheDay? get songOfTheDay => _pack.songOfTheDay;
}
