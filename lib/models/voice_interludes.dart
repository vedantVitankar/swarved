/// One recording he made for her, already uploaded to the server.
class VoiceClip {
  const VoiceClip({required this.file, this.caption = ''});

  /// The server's name for the file (sixteen hex digits and an extension).
  final String file;

  /// What it says, for him to remember. Never shown to her.
  final String caption;
}

/// When recordings surface between songs, in place of an ad, and which
/// recordings there are. Read from the `voices` part of the content.
class VoiceInterludes {
  const VoiceInterludes({
    this.everySongs = defaultEverySongs,
    this.maxPerDay,
    this.quietFrom,
    this.quietTo,
    this.restart,
    this.clips = const [],
  });

  static const none = VoiceInterludes();

  /// Used when he adds recordings but does not say how often.
  static const defaultEverySongs = 5;

  /// A voice after this many finished songs, at the earliest.
  final int everySongs;

  /// No more than this many a day, or null for no limit.
  final int? maxPerDay;

  /// Minutes after midnight between which no voice plays. Both are set, or
  /// neither counts.
  final int? quietFrom;
  final int? quietTo;

  /// Changes whenever he presses "Reset played status": every recording
  /// then counts as not played yet. Null until he does.
  final String? restart;

  final List<VoiceClip> clips;

  /// There is something to play.
  bool get isOn => clips.isNotEmpty;

  /// Whether [time] (local) falls in his quiet hours, which may run past
  /// midnight (22:00 until 07:00).
  bool isQuietAt(DateTime time) {
    final from = quietFrom;
    final to = quietTo;
    if (from == null || to == null || from == to) return false;
    final minute = time.hour * 60 + time.minute;
    return from < to
        ? minute >= from && minute < to
        : minute >= from || minute < to;
  }

  static final RegExp _clipName = RegExp(r'^[a-f0-9]{16}\.(?:mp3|m4a|ogg|wav)$');
  static final RegExp _clock = RegExp(r'^(\d{1,2}):(\d{2})$');

  /// Anything that is not a `voices` object gives [none]. Bad entries and
  /// bad numbers are skipped, never an error.
  static VoiceInterludes parse(Object? raw) {
    if (raw is! Map) return none;

    final seen = <String>{};
    final clips = <VoiceClip>[];
    final entries = raw['clips'];
    if (entries is List) {
      for (final entry in entries) {
        if (entry is! Map) continue;
        final file = entry['file'];
        if (file is! String || !_clipName.hasMatch(file) || !seen.add(file)) {
          continue;
        }
        final caption = entry['caption'];
        clips.add(VoiceClip(
          file: file,
          caption: caption is String ? caption.trim() : '',
        ));
      }
    }

    return VoiceInterludes(
      everySongs: _count(raw['everySongs']) ?? defaultEverySongs,
      maxPerDay: _count(raw['maxPerDay']),
      quietFrom: _minutes(raw['quietFrom']),
      quietTo: _minutes(raw['quietTo']),
      restart: _token(raw['resetToken']),
      clips: List.unmodifiable(clips),
    );
  }

  static String? _token(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  static int? _count(Object? value) {
    final number = switch (value) {
      int whole => whole,
      double fraction when fraction == fraction.roundToDouble() =>
        fraction.toInt(),
      String text => int.tryParse(text.trim()),
      _ => null,
    };
    return number != null && number >= 1 ? number : null;
  }

  static int? _minutes(Object? value) {
    if (value is! String) return null;
    final match = _clock.firstMatch(value.trim());
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return hour * 60 + minute;
  }
}
