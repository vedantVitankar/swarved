import 'memory.dart';

/// An "open when" letter. Before its day the server sends only that it
/// exists ([locked]); on the day it comes whole.
class Letter {
  /// The server's name for it, used to say which letters she has opened.
  final String id;

  /// "you miss me": the letter is "Open when you miss me". May be empty when
  /// there is a [title] instead.
  final String when;
  final String title;

  /// The first day it can be opened, or null.
  final DateTime? unlocksOn;

  /// True while the server is holding its words back.
  final bool locked;

  final String body;

  /// The names of uploaded files, or null.
  final String? photo;
  final String? voice;

  const Letter({
    required this.id,
    this.when = '',
    this.title = '',
    this.unlocksOn,
    this.locked = false,
    this.body = '',
    this.photo,
    this.voice,
  });

  static final _id = RegExp(r'^[a-z0-9]{4,24}$');
  static final _voice = RegExp(r'^[a-f0-9]{16}\.(?:mp3|m4a|ogg|wav)$');

  /// "Open when you miss me", or his title when there is no "when".
  String get heading => when.isNotEmpty ? 'Open when $when' : title;

  static Letter? tryParse(Object? json) {
    if (json is! Map) return null;
    final Map<dynamic, dynamic> map = json;

    String text(String key) {
      final value = map[key];
      return value is String ? value.trim() : '';
    }

    final id = text('id');
    final when = text('when');
    final title = text('title');
    if (!_id.hasMatch(id) || (when.isEmpty && title.isEmpty)) return null;

    final locked = map['locked'] == true;
    final body = text('body');
    final voice = text('voice');
    final photo = text('photo');
    final hasVoice = _voice.hasMatch(voice);
    // A letter that can be opened but has nothing in it is of no use.
    if (!locked && body.isEmpty && !hasVoice) return null;

    return Letter(
      id: id,
      when: when,
      title: title,
      unlocksOn: Memory.parseDate(text('unlocksOn')),
      locked: locked,
      body: body,
      photo: Memory.isServerPhoto(photo) ? photo : null,
      voice: hasVoice ? voice : null,
    );
  }
}
