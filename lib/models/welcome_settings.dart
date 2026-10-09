/// What the welcome screen says, as set in the content file under "welcome".
class WelcomeSettings {
  /// His handwritten line. Null uses the default.
  final String? line;

  /// How he signs it. Null uses the default.
  final String? signature;

  const WelcomeSettings({this.line, this.signature});

  /// Accepts an object with "line" and "signature", or just a string, which
  /// is taken as the line. Anything wrong falls back to the default for
  /// that part.
  static WelcomeSettings parse(Object? json) {
    if (json is String) return WelcomeSettings(line: _clean(json));
    if (json is! Map) return const WelcomeSettings();
    final Map<dynamic, dynamic> map = json;
    return WelcomeSettings(
      line: _clean(map['line']),
      signature: _clean(map['signature']),
    );
  }

  static String? _clean(Object? value) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? null : text;
  }
}
