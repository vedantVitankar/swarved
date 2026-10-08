import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/content_pack.dart';
import '../models/note_line.dart';
import '../models/note_slot.dart';
import '../models/song_note.dart';
import '../models/song_of_the_day.dart';
import '../models/track.dart';
import '../utils/daily_pick.dart';

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

  /// One of his notes for [slot], or null when he hasn't written any. The
  /// same [seed] always gives the same note. Without one, the note changes
  /// each day, walking through the list in order.
  NoteLine? lineFor(NoteSlot slot, {int? seed}) => pickBySeed(
        _pack.linesFor(slot),
        seed ?? dayNumber(DateTime.now()),
      );

  /// The note for the folder called [folder], or null.
  NoteLine? folderNoteFor(String folder) => _pack.folderNoteFor(folder);

  /// What Now Playing shows for [track]: the song's own note, else one of
  /// the general playing notes (always the same one for the same song), else
  /// nothing.
  NoteLine? noteLineFor(Track track) {
    final own = noteFor(track);
    if (own != null) return NoteLine(label: own.label, note: own.note);
    return lineFor(NoteSlot.playingNote, seed: seedFromText(track.id));
  }
}
