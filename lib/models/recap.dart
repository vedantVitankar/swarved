import 'listen_entry.dart';
import '../utils/daily_pick.dart';

/// A song and how many times it was played.
class RecapSong {
  final String title;
  final String artist;
  final int plays;

  const RecapSong({
    required this.title,
    required this.artist,
    required this.plays,
  });
}

/// What the logbook says about the time they have spent with the music.
/// Worked out from the log alone, so nothing leaves the phone.
class Recap {
  /// Plays after 22:00 and before 05:00 count as late night, matching the
  /// greeting on Home.
  static const lateNightFrom = 22;
  static const lateNightUntil = 5;

  final int plays;
  final Duration totalListened;
  final RecapSong? topSong;
  final String? topArtist;

  /// The calendar day with the most listening, and how long that was.
  final DateTime? busiestDay;
  final Duration busiestDayListened;

  /// The song played most late at night, or null if none was.
  final RecapSong? lateNightSong;

  const Recap({
    required this.plays,
    required this.totalListened,
    this.topSong,
    this.topArtist,
    this.busiestDay,
    this.busiestDayListened = Duration.zero,
    this.lateNightSong,
  });

  /// Null when [entries] is empty. Ties go to the song, artist or day seen
  /// first in [entries], which is the most recent.
  static Recap? from(List<ListenEntry> entries) {
    if (entries.isEmpty) return null;

    var total = Duration.zero;
    final artistTime = <String, Duration>{};
    final dayTime = <int, Duration>{};
    final days = <int, DateTime>{};
    for (final entry in entries) {
      total += entry.listened;

      final artist = entry.artist.trim();
      if (artist.isNotEmpty) {
        artistTime[artist] =
            (artistTime[artist] ?? Duration.zero) + entry.listened;
      }

      final day = dayNumber(entry.playedAt);
      dayTime[day] = (dayTime[day] ?? Duration.zero) + entry.listened;
      days.putIfAbsent(
        day,
        () => DateTime(
          entry.playedAt.year,
          entry.playedAt.month,
          entry.playedAt.day,
        ),
      );
    }

    String? topArtist;
    Duration? best;
    artistTime.forEach((artist, time) {
      if (best == null || time > best!) {
        topArtist = artist;
        best = time;
      }
    });

    int? busiest;
    dayTime.forEach((day, time) {
      if (busiest == null || time > dayTime[busiest]!) busiest = day;
    });

    return Recap(
      plays: entries.length,
      totalListened: total,
      topSong: _mostPlayed(entries),
      topArtist: topArtist,
      busiestDay: busiest == null ? null : days[busiest],
      busiestDayListened: busiest == null ? Duration.zero : dayTime[busiest]!,
      lateNightSong: _mostPlayed(entries.where((e) => isLateNight(e.playedAt))),
    );
  }

  static bool isLateNight(DateTime time) =>
      time.hour >= lateNightFrom || time.hour < lateNightUntil;

  static RecapSong? _mostPlayed(Iterable<ListenEntry> entries) {
    final plays = <String, int>{};
    final first = <String, ListenEntry>{};
    for (final entry in entries) {
      plays[entry.trackPath] = (plays[entry.trackPath] ?? 0) + 1;
      first.putIfAbsent(entry.trackPath, () => entry);
    }

    String? bestId;
    plays.forEach((id, count) {
      if (bestId == null || count > plays[bestId]!) bestId = id;
    });
    if (bestId == null) return null;

    final entry = first[bestId]!;
    return RecapSong(
      title: entry.title,
      artist: entry.artist,
      plays: plays[bestId]!,
    );
  }

  /// Whether the recap should be shown: the log has plays, and the first one
  /// was at least [afterDays] calendar days ago.
  static bool isReady(
    List<ListenEntry> entries,
    DateTime now, {
    required int afterDays,
  }) {
    if (entries.isEmpty) return false;
    final firstPlay = entries
        .map((e) => e.playedAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return dayNumber(now) - dayNumber(firstPlay) >= afterDays;
  }
}
