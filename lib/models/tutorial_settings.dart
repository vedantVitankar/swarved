/// The tutorial's part of the welcome file, under "tutorial":
///
///   "tutorial": {
///     "song": { "asset": "assets/welcome/song.mp3", "title": "...",
///               "artist": "...", "label": "...", "note": "..." },
///     "captions": { "play": "...", "folders": "...", ... },
///     "alwaysAskForFolder": false
///   }
///
/// Every part is optional. With nothing written, the tutorial plays
/// assets/welcome/song.mp3 if that file exists, with the title and artist
/// from its tags, and uses its built-in captions.
class TutorialSettings {
  static const defaultAsset = 'assets/welcome/song.mp3';

  /// Where the bundled song is, inside the app's assets.
  final String asset;

  /// Override what the file's tags say. Null uses the tags.
  final String? title;
  final String? artist;

  /// The gold line and handwritten note on the song's card.
  final String? label;
  final String? note;

  /// His own captions for the steps, by step name: play, folders, chips,
  /// player, search, library, addFolder, us. A step he leaves out uses the
  /// default.
  final Map<String, String> captions;

  /// The tour takes her to the Library to choose a folder, but only if she
  /// has none yet. Set this to true to be taken there anyway, which is how
  /// to test it on a phone that already has a folder.
  final bool alwaysAskForFolder;

  const TutorialSettings({
    this.asset = defaultAsset,
    this.title,
    this.artist,
    this.label,
    this.note,
    this.captions = const {},
    this.alwaysAskForFolder = false,
  });

  /// Never throws: anything wrong falls back to the default for that part.
  static TutorialSettings parse(Object? json) {
    if (json is! Map) return const TutorialSettings();
    final Map<dynamic, dynamic> map = json;
    final song = map['song'];
    final Map<dynamic, dynamic> songMap = song is Map ? song : const {};

    return TutorialSettings(
      asset: _clean(songMap['asset']) ?? defaultAsset,
      title: _clean(songMap['title']),
      artist: _clean(songMap['artist']),
      label: _clean(songMap['label']),
      note: _clean(songMap['note']),
      captions: _parseCaptions(map['captions']),
      alwaysAskForFolder: map['alwaysAskForFolder'] == true,
    );
  }

  static Map<String, String> _parseCaptions(Object? raw) {
    if (raw is! Map) return const {};
    final captions = <String, String>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      final text = _clean(entry.value);
      if (key is String && text != null) captions[key] = text;
    }
    return captions;
  }

  static String? _clean(Object? value) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? null : text;
  }
}
