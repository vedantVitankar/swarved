import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/services/stats_service.dart';

Track _track(String name, {String artist = 'Artist'}) => Track(
      filePath: '/music/$name.mp3',
      title: name,
      artist: artist,
      album: 'Album',
      duration: const Duration(minutes: 3),
      folder: 'music',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StatsService', () {
    test('starts empty', () async {
      final stats = StatsService();
      await stats.load();

      expect(stats.entries, isEmpty);
      expect(stats.todayTotal, Duration.zero);
      expect(stats.topArtist, isNull);
      expect(stats.recentUnique, isEmpty);
    });

    test('todayTotal adds up everything listened today', () async {
      final stats = StatsService();
      await stats.logListen(_track('a'), const Duration(seconds: 120));
      await stats.logListen(_track('b'), const Duration(seconds: 30));

      expect(stats.todayTotal, const Duration(seconds: 150));
    });

    test('recentUnique drops repeats and keeps the latest first', () async {
      final stats = StatsService();
      await stats.logListen(_track('a'), const Duration(seconds: 60));
      await stats.logListen(_track('b'), const Duration(seconds: 60));
      await stats.logListen(_track('a'), const Duration(seconds: 60));

      expect(
        stats.recentUnique.map((e) => e.trackPath).toList(),
        ['/music/a.mp3', '/music/b.mp3'],
      );
    });

    test('recentUnique stops at ten tracks', () async {
      final stats = StatsService();
      for (var i = 0; i < 12; i++) {
        await stats.logListen(_track('t$i'), const Duration(seconds: 60));
      }

      expect(stats.recentUnique.length, 10);
      expect(stats.recentUnique.first.title, 't11');
    });

    test('topArtist is decided by total time, not play count', () async {
      final stats = StatsService();
      await stats.logListen(
          _track('a', artist: 'Long'), const Duration(seconds: 200));
      await stats.logListen(
          _track('b', artist: 'Short'), const Duration(seconds: 60));
      await stats.logListen(
          _track('c', artist: 'Short'), const Duration(seconds: 60));

      expect(stats.topArtist, 'Long');
    });

    test('a new service loads what the last one saved', () async {
      final first = StatsService();
      await first.logListen(_track('a'), const Duration(seconds: 90));

      final second = StatsService();
      await second.load();

      expect(second.entries.length, 1);
      expect(second.entries.first.title, 'a');
      expect(second.todayTotal, const Duration(seconds: 90));
    });
  });
}
