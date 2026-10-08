/// How the recap is set in the content file, under "recap".
class RecapSettings {
  static const defaultAfterDays = 30;

  /// Days after her first logged play before the recap appears.
  final int afterDays;

  /// His closing line. Null uses the default.
  final String? line;

  const RecapSettings({this.afterDays = defaultAfterDays, this.line});

  /// Anything wrong in [json] falls back to the default for that part.
  static RecapSettings parse(Object? json) {
    if (json is! Map) return const RecapSettings();
    final Map<dynamic, dynamic> map = json;

    final days = map['afterDays'];
    final line = map['line'];
    final trimmed = line is String ? line.trim() : '';
    return RecapSettings(
      afterDays: days is num && days >= 0 ? days.floor() : defaultAfterDays,
      line: trimmed.isEmpty ? null : trimmed,
    );
  }
}
