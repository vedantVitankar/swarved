import '../models/voice_interludes.dart';

/// Decides whether a voice plays between two songs, and which one. Pure:
/// everything it needs is passed in, so every rule can be tested.
///
/// The recordings play in his order and never start over by themselves. The
/// ones after the one played last are "waiting"; the rest are "played". So a
/// recording he adds at the end is always heard next, and one he moves below
/// the last played one is heard again. When nothing is waiting, no voice
/// plays until he adds something or resets the list.
class VoicePlanner {
  const VoicePlanner();

  /// The recordings still to be heard, in order.
  ///
  /// With [last] (the one played last) still in the list, they are the ones
  /// after it. Without it (never played, or since removed), they are the
  /// ones not in [played].
  static List<VoiceClip> waiting(
    List<VoiceClip> clips, {
    String? last,
    Set<String> played = const {},
  }) {
    final at =
        last == null ? -1 : clips.indexWhere((clip) => clip.file == last);
    if (at >= 0) return clips.sublist(at + 1);
    return [
      for (final clip in clips)
        if (!played.contains(clip.file)) clip,
    ];
  }

  /// The recording to play now, or null for none.
  ///
  /// - [songsSince]: songs finished since the last voice, this one included.
  /// - [playedToday]: voices already played today.
  /// - [onPhone]: the file names that are downloaded. The next waiting
  ///   recording is never skipped: if it is not here yet, no voice plays.
  VoiceClip? choose({
    required VoiceInterludes settings,
    required int songsSince,
    required int playedToday,
    required DateTime now,
    required Set<String> onPhone,
    String? last,
    Set<String> played = const {},
  }) {
    if (songsSince < settings.everySongs) return null;
    final limit = settings.maxPerDay;
    if (limit != null && playedToday >= limit) return null;
    if (settings.isQuietAt(now)) return null;

    final next = waiting(settings.clips, last: last, played: played);
    if (next.isEmpty) return null;
    return onPhone.contains(next.first.file) ? next.first : null;
  }
}
