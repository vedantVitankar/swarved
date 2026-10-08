import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/content_pack.dart';
import 'package:swarved/models/listen_entry.dart';
import 'package:swarved/models/recap.dart';
import 'package:swarved/models/recap_settings.dart';
import 'package:swarved/utils/duration_format.dart';

ListenEntry _play(
  String id,
  DateTime at, {
  String artist = 'Artist',
  int seconds = 180,
}) =>
    ListenEntry(
      trackPath: id,
      title: 'Song $id',
      artist: artist,
      playedAt: at,
      listened: Duration(seconds: seconds),
    );

void main() {
  group('Recap.from', () {
    test('no plays gives no recap', () {
      expect(Recap.from([]), isNull);
    });

    test('counts plays and adds up the listening time', () {
      final recap = Recap.from([
        _play('a', DateTime(2026, 3, 1, 10), seconds: 60),
        _play('b', DateTime(2026, 3, 2, 10), seconds: 120),
      ])!;
      expect(recap.plays, 2);
      expect(recap.totalListened, const Duration(seconds: 180));
    });

    test('the top song is the most played, by track id', () {
      final recap = Recap.from([
        _play('a', DateTime(2026, 3, 1, 10)),
        _play('b', DateTime(2026, 3, 1, 11)),
        _play('b', DateTime(2026, 3, 2, 11)),
      ])!;
      expect(recap.topSong?.title, 'Song b');
      expect(recap.topSong?.plays, 2);
    });

    test('a tie goes to the song seen first, the most recent', () {
      final recap = Recap.from([
        _play('new', DateTime(2026, 3, 2, 10)),
        _play('old', DateTime(2026, 3, 1, 10)),
      ])!;
      expect(recap.topSong?.title, 'Song new');
    });

    test('the top artist is the one with the most listening time', () {
      final recap = Recap.from([
        _play('a', DateTime(2026, 3, 1, 10), artist: 'One', seconds: 100),
        _play('b', DateTime(2026, 3, 1, 11), artist: 'Two', seconds: 300),
        _play('c', DateTime(2026, 3, 1, 12), artist: 'One', seconds: 100),
      ])!;
      expect(recap.topArtist, 'Two');
    });

    test('songs with no artist never become the top artist', () {
      final recap = Recap.from([
        _play('a', DateTime(2026, 3, 1, 10), artist: '', seconds: 900),
        _play('b', DateTime(2026, 3, 1, 11), artist: 'Named', seconds: 10),
      ])!;
      expect(recap.topArtist, 'Named');
    });

    test('the busiest day is the one with the most listening', () {
      final recap = Recap.from([
        _play('a', DateTime(2026, 3, 1, 9), seconds: 100),
        _play('b', DateTime(2026, 3, 2, 9), seconds: 200),
        _play('c', DateTime(2026, 3, 2, 21), seconds: 200),
      ])!;
      expect(recap.busiestDay, DateTime(2026, 3, 2));
      expect(recap.busiestDayListened, const Duration(seconds: 400));
    });

    test('late night means 22:00 to 04:59', () {
      expect(Recap.isLateNight(DateTime(2026, 3, 1, 22)), isTrue);
      expect(Recap.isLateNight(DateTime(2026, 3, 1, 4, 59)), isTrue);
      expect(Recap.isLateNight(DateTime(2026, 3, 1, 5)), isFalse);
      expect(Recap.isLateNight(DateTime(2026, 3, 1, 21, 59)), isFalse);
    });

    test('the late-night song counts only late-night plays', () {
      final recap = Recap.from([
        _play('day', DateTime(2026, 3, 1, 12)),
        _play('day', DateTime(2026, 3, 2, 12)),
        _play('day', DateTime(2026, 3, 3, 12)),
        _play('night', DateTime(2026, 3, 1, 23)),
      ])!;
      expect(recap.topSong?.title, 'Song day');
      expect(recap.lateNightSong?.title, 'Song night');
    });

    test('no late-night plays means no late-night song', () {
      final recap = Recap.from([_play('a', DateTime(2026, 3, 1, 12))])!;
      expect(recap.lateNightSong, isNull);
    });
  });

  group('Recap.isReady', () {
    final now = DateTime(2026, 4, 1, 9);

    test('no plays is never ready', () {
      expect(Recap.isReady([], now, afterDays: 0), isFalse);
    });

    test('waits until the first play is old enough', () {
      final entries = [_play('a', DateTime(2026, 3, 2, 23, 59))];
      expect(Recap.isReady(entries, now, afterDays: 30), isTrue);
      expect(Recap.isReady(entries, now, afterDays: 31), isFalse);
    });

    test('goes by the oldest play, wherever it is in the list', () {
      final entries = [
        _play('new', DateTime(2026, 3, 31)),
        _play('old', DateTime(2026, 1, 1)),
      ];
      expect(Recap.isReady(entries, now, afterDays: 60), isTrue);
    });

    test('counts calendar days, not hours', () {
      final entries = [_play('a', DateTime(2026, 3, 31, 23, 59))];
      expect(Recap.isReady(entries, DateTime(2026, 4, 1, 0, 1), afterDays: 1),
          isTrue);
    });
  });

  group('RecapSettings.parse', () {
    test('reads the days and the closing line', () {
      final s = RecapSettings.parse({'afterDays': 45, 'line': ' Always. '});
      expect(s.afterDays, 45);
      expect(s.line, 'Always.');
    });

    test('falls back to the defaults for anything wrong', () {
      for (final bad in [null, 'x', 5, <String, Object?>{}]) {
        final s = RecapSettings.parse(bad);
        expect(s.afterDays, RecapSettings.defaultAfterDays);
        expect(s.line, isNull);
      }
      expect(RecapSettings.parse({'afterDays': -3}).afterDays, 30);
      expect(RecapSettings.parse({'afterDays': 'soon'}).afterDays, 30);
      expect(RecapSettings.parse({'line': '  '}).line, isNull);
    });

    test('a content file carries them, and defaults without them', () {
      expect(ContentPack.parse('{"recap": {"afterDays": 7}}').recap.afterDays, 7);
      expect(ContentPack.parse('{}').recap.afterDays, 30);
    });
  });

  group('listenedLabel', () {
    test('writes minutes and hours in words', () {
      expect(listenedLabel(const Duration(seconds: 30)), 'less than a minute');
      expect(listenedLabel(const Duration(minutes: 42)), '42 min');
      expect(listenedLabel(const Duration(hours: 5)), '5 h');
      expect(listenedLabel(const Duration(hours: 5, minutes: 30)), '5 h 30 min');
    });
  });
}
