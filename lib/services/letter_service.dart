import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'letters_opened_reporter.dart';

/// Which "open when" letters she has opened, and when. Kept on this device,
/// and told to the server each time one is opened (and once at start, so a
/// report that was missed is made up).
class LetterService extends ChangeNotifier {
  LetterService({
    required LettersOpenedReporter reporter,
    DateTime Function()? clock,
  })  : _reporter = reporter,
        _clock = clock ?? DateTime.now;

  static const _key = 'letters_opened';

  final LettersOpenedReporter _reporter;
  final DateTime Function() _clock;
  final Map<String, DateTime> _opened = {};

  bool isOpened(String id) => _opened.containsKey(id);

  /// Reads what was saved, and tells the server about it. Never throws.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved != null) {
        final decoded = jsonDecode(saved);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            final at = entry.value is String
                ? DateTime.tryParse(entry.value as String)
                : null;
            if (entry.key is String && at != null) {
              _opened[entry.key as String] = at;
            }
          }
        }
      }
    } catch (error) {
      debugPrint('Opened letters not read: $error');
    }
    if (_opened.isNotEmpty) unawaited(_reporter.report(Map.of(_opened)));
    notifyListeners();
  }

  /// Notes that she opened the letter, the first time only.
  Future<void> markOpened(String id) async {
    if (_opened.containsKey(id)) return;
    _opened[id] = _clock();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode({
          for (final entry in _opened.entries)
            entry.key: entry.value.toUtc().toIso8601String(),
        }),
      );
    } catch (error) {
      debugPrint('Opened letter not saved: $error');
    }
    unawaited(_reporter.report(Map.of(_opened)));
  }
}
