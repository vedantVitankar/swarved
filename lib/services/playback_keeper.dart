import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../models/saved_queue.dart';
import '../models/track.dart';
import '../utils/save_schedule.dart';
import 'player_service.dart';
import 'saved_queue_store.dart';

/// Keeps what is playing saved, and puts it back the next time the app opens:
/// the queue, its order, the song she was on, the playlist it came from, and
/// the second she had reached. It comes back paused; pressing play carries on.
///
/// It only watches the player and writes a small file. When to write is
/// [SaveSchedule]'s decision, and what is written is [SavedQueue].
class PlaybackKeeper {
  PlaybackKeeper({
    required this.player,
    required this.store,
    this.libraryTracks = _noTracks,
    this.fileExists = _fileExists,
    SaveSchedule? schedule,
    DateTime Function()? clock,
  })  : _schedule = schedule ?? SaveSchedule(),
        _clock = clock ?? DateTime.now;

  final PlayerService player;
  final SavedQueueStore store;

  /// The songs found in her music folders, to put a local song's picture back
  /// (the picture itself is never saved).
  final List<Track> Function() libraryTracks;

  /// Whether a local song's file is still there.
  final bool Function(String path) fileExists;

  final SaveSchedule _schedule;
  final DateTime Function() _clock;

  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  bool _started = false;
  bool _writing = false;

  static List<Track> _noTracks() => const [];
  static bool _fileExists(String path) => File(path).existsSync();

  /// Puts back the last queue, then starts keeping the saved one up to date.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _restore();
    player.addListener(_check);
    // The player only speaks when something changes; the timer is what makes
    // sure a position that keeps moving is still written now and then.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _check());
    // Going to the background (or being closed) may be the last chance.
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        if (state == AppLifecycleState.resumed) return;
        _schedule.saveNext();
        _check();
      },
    );
  }

  void dispose() {
    player.removeListener(_check);
    _timer?.cancel();
    _lifecycle?.dispose();
  }

  Future<void> _restore() async {
    try {
      final saved = await store.read();
      if (saved == null) return;
      final pictures = {for (final t in libraryTracks()) t.filePath: t};
      // A song whose file she has since deleted is left out.
      final kept = saved.keeping((t) => !t.isLocal || fileExists(t.filePath));
      if (kept == null) return;
      final restored = player.restore(
        kept.mapTracks((t) => t.isLocal ? (pictures[t.filePath] ?? t) : t),
      );
      // When nothing was left out the file already says exactly this, so it
      // is not written again until something changes. If a song was left
      // out, the corrected queue is written soon.
      final signature = player.saveSignature;
      if (restored && identical(kept, saved) && signature != null) {
        _schedule.saved(
          signature: signature,
          position: player.positionToSave,
          now: _clock(),
        );
      }
    } catch (e) {
      // A queue that cannot be put back is not worth failing the app for.
      debugPrint('Could not put back the last queue: $e');
    }
  }

  void _check() {
    if (_writing) return;
    final signature = player.saveSignature;
    if (signature == null) return; // nothing worth saving (the saved one stays)
    final now = _clock();
    if (!_schedule.shouldSave(
      signature: signature,
      playing: player.isPlaying,
      position: player.positionToSave,
      now: now,
    )) {
      return;
    }
    final saved = player.snapshot();
    if (saved == null) return;
    unawaited(_write(saved, signature, now));
  }

  Future<void> _write(SavedQueue saved, String signature, DateTime now) async {
    _writing = true;
    try {
      await store.write(saved);
      _schedule.saved(signature: signature, position: saved.position, now: now);
    } catch (e) {
      // It is asked for again on the next tick.
      debugPrint('Could not save the queue: $e');
    } finally {
      _writing = false;
    }
  }
}
