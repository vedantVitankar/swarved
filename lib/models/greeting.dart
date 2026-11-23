/// One greeting he wrote for the top of Home, for the hours from [from] until
/// [to], with an optional small gold line to show under it.
///
/// The times are minutes after midnight. A greeting whose end is earlier than
/// its start runs past midnight (22:00 until 05:00), and one that ends where
/// another begins does not overlap it: the start counts, the end does not.
class Greeting {
  final int from;
  final int to;

  /// His words, as written. A line break in them is kept.
  final String text;

  /// The small gold line under the greeting, or null to use the usual one.
  final String? gold;

  const Greeting({
    required this.from,
    required this.to,
    required this.text,
    this.gold,
  });

  /// Null for anything that can't be used: not an object, no words, a time
  /// that isn't "HH:MM", or the same start and end (which would never show).
  /// One bad entry never spoils the others.
  static Greeting? tryParse(Object? json) {
    if (json is! Map) return null;
    final text = json['text'];
    if (text is! String || text.trim().isEmpty) return null;
    final from = _minutes(json['from']);
    final to = _minutes(json['to']);
    if (from == null || to == null || from == to) return null;
    final gold = json['gold'];
    final goldText = gold is String ? gold.trim() : '';
    return Greeting(
      from: from,
      to: to,
      text: text.trim(),
      gold: goldText.isEmpty ? null : goldText,
    );
  }

  static final RegExp _time = RegExp(r'^(\d{1,2}):(\d{2})$');

  static int? _minutes(Object? value) {
    if (value is! String) return null;
    final match = _time.firstMatch(value.trim());
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return hour * 60 + minute;
  }

  /// Whether [now] (a local time) falls in this greeting's hours.
  bool covers(DateTime now) {
    final minute = now.hour * 60 + now.minute;
    return from < to
        ? minute >= from && minute < to
        : minute >= from || minute < to;
  }

  @override
  bool operator ==(Object other) =>
      other is Greeting &&
      other.from == from &&
      other.to == to &&
      other.text == text &&
      other.gold == gold;

  @override
  int get hashCode => Object.hash(from, to, text, gold);
}
