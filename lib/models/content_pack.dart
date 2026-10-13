import 'dart:convert';
import 'memory.dart';
import 'note_line.dart';
import 'recap_settings.dart';
import 'note_slot.dart';
import 'song_note.dart';
import 'song_of_the_day.dart';
import 'track.dart';
import '../utils/song_match.dart';

/// Everything he has written for her, as one immutable bundle.
/// Later phases add more to this (playlists, voice).
class ContentPack {
  final List<SongNote> notes;

  /// The song he picked for today, or null when he hasn't picked one.
  final SongOfTheDay? songOfTheDay;

  /// His notes for the places around the app. A slot with no notes is
  /// simply absent.
  final Map<NoteSlot, List<NoteLine>> slots;

  /// A note for a folder, keyed by the folder name as [normalizeForMatch]
  /// sees it, so "Slow dances" and "slow  dances!" are the same folder.
  final Map<String, NoteLine> folderNotes;

  /// Moments for memory lane, oldest first.
  final List<Memory> memories;

  /// When the recap appears and what he says at the end of it.
  final RecapSettings recap;

  /// Words he has written for a named place in the app (the Search page's
  /// heading, say), keyed by that name. Only non-empty words are kept.
  final Map<String, String> texts;

  /// Every uploaded photo or voice file the content mentions, wherever it
  /// is mentioned, so nothing the content still uses is ever cleaned away.
  final Set<String> mediaFiles;

  const ContentPack({
    this.notes = const [],
    this.songOfTheDay,
    this.slots = const {},
    this.folderNotes = const {},
    this.memories = const [],
    this.recap = const RecapSettings(),
    this.texts = const {},
    this.mediaFiles = const {},
  });

  static const empty = ContentPack();

  /// Throws [FormatException] when [source] isn't a JSON object.
  /// Individual bad entries are skipped, and a bad song of the day is
  /// treated as none.
  factory ContentPack.parse(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Content must be a JSON object');
    }
    final raw = decoded['notes'];
    final notes = <SongNote>[];
    if (raw is List) {
      for (final item in raw) {
        final note = SongNote.tryParse(item);
        if (note != null) notes.add(note);
      }
    }
    return ContentPack(
      notes: List.unmodifiable(notes),
      songOfTheDay: SongOfTheDay.tryParse(decoded['songOfTheDay']),
      slots: _parseSlots(decoded['slots']),
      folderNotes: _parseFolderNotes(decoded['folderNotes']),
      memories: _parseMemories(decoded['memories']),
      recap: RecapSettings.parse(decoded['recap']),
      texts: _parseTexts(decoded['texts']),
      mediaFiles: Set.unmodifiable({
        for (final match in _mediaName.allMatches(source)) match.group(0)!,
      }),
    );
  }

  /// The names the server gives uploaded files.
  static final RegExp _mediaName =
      RegExp(r'[a-f0-9]{16}\.(?:jpg|png|webp|mp3|m4a|ogg|wav)');

  static Map<String, String> _parseTexts(Object? raw) {
    if (raw is! Map) return const {};
    final texts = <String, String>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! String) continue;
      final words = value.trim();
      if (words.isNotEmpty) texts[key] = words;
    }
    return Map.unmodifiable(texts);
  }

  static List<Memory> _parseMemories(Object? raw) {
    if (raw is! List) return const [];
    return Memory.inOrder([
      for (final entry in raw) Memory.tryParse(entry),
    ].whereType<Memory>());
  }

  static Map<NoteSlot, List<NoteLine>> _parseSlots(Object? raw) {
    if (raw is! Map) return const {};
    final slots = <NoteSlot, List<NoteLine>>{};
    for (final slot in NoteSlot.values) {
      final entries = raw[slot.name];
      if (entries is! List) continue;
      final lines = [
        for (final entry in entries) NoteLine.tryParse(entry),
      ].whereType<NoteLine>().toList();
      if (lines.isNotEmpty) slots[slot] = List.unmodifiable(lines);
    }
    return Map.unmodifiable(slots);
  }

  static Map<String, NoteLine> _parseFolderNotes(Object? raw) {
    if (raw is! List) return const {};
    final notes = <String, NoteLine>{};
    for (final entry in raw) {
      if (entry is! Map) continue;
      final folder = entry['folder'];
      final line = NoteLine.tryParse(entry);
      if (folder is! String || line == null) continue;
      final key = normalizeForMatch(folder);
      if (key.isNotEmpty) notes.putIfAbsent(key, () => line);
    }
    return Map.unmodifiable(notes);
  }

  /// His words for the place called [key], or null when he wrote none.
  String? textFor(String key) => texts[key];

  /// His notes for [slot], possibly none.
  List<NoteLine> linesFor(NoteSlot slot) => slots[slot] ?? const [];

  /// The note for the folder called [folder], or null.
  NoteLine? folderNoteFor(String folder) =>
      folderNotes[normalizeForMatch(folder)];

  /// The first note that belongs to [track], or null.
  SongNote? noteFor(Track track) {
    for (final note in notes) {
      if (songMatches(note, track)) return note;
    }
    return null;
  }
}
