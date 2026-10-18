import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/voice_interludes.dart';
import '../utils/voice_planner.dart';

const _kDayKey = 'voice_day_v1';
const _kLastKey = 'voice_last_v1';
const _kPlayedKey = 'voice_played_v1';
const _kResetKey = 'voice_reset_v1';

/// The file when it is already on this phone, or null. Never downloads.
typedef VoiceFileLookup = Future<File?> Function(String name);

/// Starts downloading a recording in the background.
typedef VoiceDownload = void Function(String name);

/// Tells the server how far this phone has got: the recording played last
/// and every one played so far.
typedef VoiceProgressReport = void Function(String? last, List<String> played);

/// Between two songs, says whether a recording of his plays now. The player
/// asks once each time a song ends by itself.
///
/// The recordings play in his order and never start over by themselves (see
/// VoicePlanner). This keeps which one played last, which have played and how
/// many played today, tells the server so the admin site can mark each one
/// "Played" or "Waiting", and starts over when he presses "Reset played
/// status". It only ever plays a recording that is already on the phone, so
/// music never waits for a download; one that is missing is fetched in the
/// background for next time. It never throws.
class VoiceInterludeService {
  VoiceInterludeService({
    required VoiceInterludes Function() settings,
    required VoiceFileLookup onPhone,
    VoiceDownload? download,
    VoiceProgressReport? report,
    VoicePlanner? planner,
    DateTime Function()? clock,
  })  : _settings = settings,
        _onPhone = onPhone,
        _download = download,
        _report = report,
        _planner = planner ?? const VoicePlanner(),
        _clock = clock ?? DateTime.now;

  final VoiceInterludes Function() _settings;
  final VoiceFileLookup _onPhone;
  final VoiceDownload? _download;
  final VoiceProgressReport? _report;
  final VoicePlanner _planner;
  final DateTime Function() _clock;

  int _songsSince = 0;

  /// A song has just finished: the recording to play before the next one, or
  /// null for none.
  Future<File?> afterSong() async {
    try {
      final settings = _settings();
      if (!settings.isOn) return null;
      final prefs = await SharedPreferences.getInstance();

      // He pressed "Reset played status": everything is waiting again.
      final restart = settings.restart;
      if (restart != null && restart != prefs.getString(_kResetKey)) {
        await prefs.setString(_kResetKey, restart);
        await prefs.remove(_kLastKey);
        await prefs.remove(_kPlayedKey);
        _report?.call(null, const []);
      }

      _songsSince++;
      final now = _clock();
      final today = _dayKey(now);
      final playedToday = _playedOn(prefs.getString(_kDayKey), today);
      final last = prefs.getString(_kLastKey);
      final played = prefs.getStringList(_kPlayedKey) ?? const <String>[];

      final files = <String, File>{};
      for (final clip in settings.clips) {
        final file = await _onPhone(clip.file);
        if (file != null) files[clip.file] = file;
      }

      final clip = _planner.choose(
        settings: settings,
        songsSince: _songsSince,
        playedToday: playedToday,
        now: now,
        onPhone: files.keys.toSet(),
        last: last,
        played: played.toSet(),
      );

      if (clip == null) {
        // The next recording in line may simply not be on the phone yet:
        // fetch it now, so it is there for the next time.
        final waiting = VoicePlanner.waiting(
          settings.clips,
          last: last,
          played: played.toSet(),
        );
        if (waiting.isNotEmpty && !files.containsKey(waiting.first.file)) {
          debugPrint('Voice ${waiting.first.file} is next but not on this '
              'phone yet: fetching it');
          _download?.call(waiting.first.file);
        }
        return null;
      }

      _songsSince = 0;
      final nowPlayed = [
        ...played.where((name) => name != clip.file),
        clip.file,
      ];
      await prefs.setString(_kDayKey, '$today:${playedToday + 1}');
      await prefs.setString(_kLastKey, clip.file);
      await prefs.setStringList(_kPlayedKey, nowPlayed);
      _report?.call(clip.file, nowPlayed);
      return files[clip.file];
    } catch (error) {
      debugPrint('Voice not chosen: $error');
      return null;
    }
  }

  static String _dayKey(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)}';
  }

  /// How many voices the saved "day:count" says played on [today].
  static int _playedOn(String? saved, String today) {
    if (saved == null) return 0;
    final parts = saved.split(':');
    if (parts.length != 2 || parts.first != today) return 0;
    return int.tryParse(parts.last) ?? 0;
  }
}
