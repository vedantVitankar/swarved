import '../models/voice_interludes.dart';

/// Decides whether a voice plays between two songs, and which one. Pure:
/// everything it needs is passed in, so every rule can be tested.
///
/// The recordings play in the order he put them in, one after another, and
/// start again from the top after the last. Moving them around, or adding
/// new ones, simply changes what comes after the one she heard last.
class VoicePlanner {
  const VoicePlanner();

  /// The recording to play now, or null for none.
  ///
  /// - [songsSince]: songs finished since the last voice, this one included.
  /// - [playedToday]: voices already played today.
  /// - [onPhone]: the file names that are downloaded; a voice that is not
  ///   here yet is skipped over, never waited for.
  /// - [lastPlayed]: the file played last, or null (or one no longer in the
  ///   list) to start from the first.
  VoiceClip? choose({
    required VoiceInterludes settings,
    required int songsSince,
    required int playedToday,
    required DateTime now,
    required Set<String> onPhone,
    String? lastPlayed,
  }) {
    if (songsSince < settings.everySongs) return null;
    final limit = settings.maxPerDay;
    if (limit != null && playedToday >= limit) return null;
    if (settings.isQuietAt(now)) return null;

    final clips = settings.clips;
    final last = lastPlayed == null
        ? -1
        : clips.indexWhere((clip) => clip.file == lastPlayed);
    // From the one after the last played, round the list, ending with the
    // last one itself (the only one there is, for a list of one).
    for (var step = 1; step <= clips.length; step++) {
      final clip = clips[(last + step) % clips.length];
      if (onPhone.contains(clip.file)) return clip;
    }
    return null;
  }
}
