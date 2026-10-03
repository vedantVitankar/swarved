import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/listen_entry.dart';
import '../models/track.dart';

const _kLogKey = 'listen_log_v1';
const _kMaxEntries = 500;

class StatsService extends ChangeNotifier {
  List<ListenEntry> _entries = [];

  List<ListenEntry> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLogKey);
    if (raw == null) return;
    final list = jsonDecode(raw) as List<dynamic>;
    _entries = list
        .map((e) => ListenEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<void> logListen(Track track, Duration listened) async {
    _entries.insert(
      0,
      ListenEntry(
        trackPath: track.filePath,
        title: track.title,
        artist: track.artist,
        playedAt: DateTime.now(),
        listened: listened,
      ),
    );
    if (_entries.length > _kMaxEntries) {
      _entries = _entries.sublist(0, _kMaxEntries);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kLogKey,
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
  }

  /// Total listened time for entries played today.
  Duration get todayTotal {
    final now = DateTime.now();
    final today = _entries.where((e) =>
        e.playedAt.year == now.year &&
        e.playedAt.month == now.month &&
        e.playedAt.day == now.day);
    return today.fold(Duration.zero, (sum, e) => sum + e.listened);
  }

  /// Recently played tracks, deduplicated by track path, most recent first.
  List<ListenEntry> get recentUnique {
    final seen = <String>{};
    final result = <ListenEntry>[];
    for (final e in _entries) {
      if (seen.add(e.trackPath)) result.add(e);
      if (result.length >= 10) break;
    }
    return result;
  }

  /// Most played artist by cumulative listened time.
  String? get topArtist {
    if (_entries.isEmpty) return null;
    final totals = <String, Duration>{};
    for (final e in _entries) {
      totals[e.artist] = (totals[e.artist] ?? Duration.zero) + e.listened;
    }
    return totals.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}
