import 'note_line.dart';
import 'tutorial_settings.dart';

/// What the welcome screen says, as set in its own file,
/// assets/welcome/welcome.json (see WelcomeService).
class WelcomeSettings {
  /// His handwritten line on the first page. Null uses the default.
  final String? line;

  /// How he signs it. Null uses the default.
  final String? signature;

  /// Why he made it, one short paragraph each. Empty uses the default.
  final List<String> story;

  /// The notes in the carousel. Empty uses the default.
  final List<NoteLine> notes;

  /// The tutorial that follows the welcome: its song and its captions.
  final TutorialSettings tutorial;

  const WelcomeSettings({
    this.line,
    this.signature,
    this.story = const [],
    this.notes = const [],
    this.tutorial = const TutorialSettings(),
  });

  /// Accepts an object with "line", "signature", "story" and "notes", or
  /// just a string, which is taken as the line. Anything wrong falls back to
  /// the default for that part, and one bad entry never spoils the rest.
  static WelcomeSettings parse(Object? json) {
    if (json is String) return WelcomeSettings(line: _clean(json));
    if (json is! Map) return const WelcomeSettings();
    final Map<dynamic, dynamic> map = json;
    return WelcomeSettings(
      line: _clean(map['line']),
      signature: _clean(map['signature']),
      story: _parseStory(map['story']),
      notes: _parseNotes(map['notes']),
      tutorial: TutorialSettings.parse(map['tutorial']),
    );
  }

  /// A list of paragraphs, or one string, which is one paragraph.
  static List<String> _parseStory(Object? raw) {
    if (raw is String) {
      final text = _clean(raw);
      return text == null ? const [] : [text];
    }
    if (raw is! List) return const [];
    final paragraphs = <String>[];
    for (final entry in raw) {
      final text = _clean(entry);
      if (text != null) paragraphs.add(text);
    }
    return paragraphs;
  }

  static List<NoteLine> _parseNotes(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final entry in raw) NoteLine.tryParse(entry),
    ].whereType<NoteLine>().toList();
  }

  static String? _clean(Object? value) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? null : text;
  }
}
