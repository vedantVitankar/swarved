import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/voice_interludes.dart';
import '../utils/voice_planner.dart';

const _kDayKey = 'voice_day_v1';
const _kLastKey = 'voice_last_v1';

/// The file when it is already on this phone, or null. Never downloads.
typedef VoiceFileLookup = Future<File?> Function(String name);

/// Between two songs, says whether a recording of his plays now. The player
/// asks once each time a song ends by itself.
///
/// It counts finished songs and keeps how many voices played today and which
/// one played last, so the recordings go round in his order (see
/// VoicePlanner). It only ever picks a recording that is already on the
/// phone, so music never waits for a download. It never throws.
class VoiceInterludeService {
  VoiceInterludeService({
    required VoiceInterludes Function() settings,
    required VoiceFileLookup onPhone,
    VoicePlanner? planner,
    DateTime Function()? clock,
  })  : _settings = settings,
        _onPhone = onPhone,
        _planner = planner ?? const VoicePlanner(),
        _clock = clock ?? DateTime.now;

  final VoiceInterludes Function() _settings;
  final VoiceFileLookup _onPhone;
  final VoicePlanner _planner;
  final DateTime Function() _clock;

  int _songsSince = 0;

  /// A song has just finished: the recording to play before the next one, or
  /// null for none.
  Future<File?> afterSong() async {
    try {
      final settings = _settings();
      if (!settings.isOn) return null;
      _songsSince++;
      final now = _clock();

      final prefs = await SharedPreferences.getInstance();
      final today = _dayKey(now);
      final playedToday = _playedOn(prefs.getString(_kDayKey), today);
      final last = prefs.getString(_kLastKey);

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
        lastPlayed: last,
      );
      if (clip == null) return null;

      _songsSince = 0;
      await prefs.setString(_kDayKey, '$today:${playedToday + 1}');
      await prefs.setString(_kLastKey, clip.file);
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
