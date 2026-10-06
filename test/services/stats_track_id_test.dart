import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/services/stats_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a log saved before YouTube support still loads', () async {
    SharedPreferences.setMockInitialValues({
      'listen_log_v1': jsonEncode([
        {
          'trackPath': '/music/love/song.mp3',
          'title': 'Song',
          'artist': 'Artist',
          'playedAt': '2026-10-01T20:00:00.000',
          'listenedSeconds': 180,
        },
      ]),
    });

    final stats = StatsService();
    await stats.load();

    expect(stats.entries.single.trackPath, '/music/love/song.mp3');
    expect(stats.entries.single.listened, const Duration(seconds: 180));
  });

  test('a local listen is logged by its file path, as before', () async {
    SharedPreferences.setMockInitialValues({});
    final stats = StatsService();

    await stats.logListen(
      Track(
        filePath: '/music/a.mp3',
        title: 'A',
        artist: 'Artist',
        album: 'Album',
        duration: const Duration(minutes: 3),
        folder: 'music',
      ),
      const Duration(seconds: 60),
    );

    expect(stats.entries.first.trackPath, '/music/a.mp3');
  });

  test('a YouTube listen is logged by its yt: id', () async {
    SharedPreferences.setMockInitialValues({});
    final stats = StatsService();

    await stats.logListen(
      Track.youtube(
        videoId: 'abc123',
        title: 'Song',
        artist: 'Channel',
        duration: const Duration(minutes: 4),
      ),
      const Duration(seconds: 90),
    );

    expect(stats.entries.first.trackPath, 'yt:abc123');
  });
}
