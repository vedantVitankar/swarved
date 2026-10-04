import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/track.dart';
import 'stats_service.dart';

/// just_audio_background (and the MediaItem tag it requires) only works
/// on Android, iOS, and macOS — audio_service doesn't support Windows or
/// Linux. This must match the same check in main.dart.
bool get _supportsBackgroundPlayback =>
    Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

/// A manual skip/switch only counts toward listening stats once the user
/// has actually heard at least this much of the track. A natural full
/// completion always counts in full, regardless of this threshold (see
/// _logCurrentListen below) — a 10-second jingle that plays to the end
/// should still count, even though it's under 30 seconds.
const _kMinPartialListenThreshold = Duration(seconds: 30);

class PlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final StatsService statsService;

  List<Track> _queue = [];
  int _currentIndex = -1;

  PlayerService(this.statsService) {
    _player.playerStateStream.listen((_) => notifyListeners());
    _player.positionStream.listen((_) => notifyListeners());

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        // Log the just-finished track as a full, natural completion —
        // then advance WITHOUT letting next() log it a second time.
        _logCurrentListen(completedNaturally: true);
        _advanceAfterCompletion();
      }
    });
  }

  Track? get current =>
      _currentIndex >= 0 && _currentIndex < _queue.length
          ? _queue[_currentIndex]
          : null;

  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration get bufferedPosition => _player.bufferedPosition;
  Duration get duration => _player.duration ?? Duration.zero;
  List<Track> get queue => _queue;
  int get currentIndex => _currentIndex;

  Future<void> playQueue(List<Track> tracks, {int startIndex = 0}) async {
    _logCurrentListen(completedNaturally: false);
    _queue = tracks;
    _currentIndex = startIndex;
    await _loadCurrent();
    await _player.play();
  }

  Future<void> _loadCurrent() async {
    final track = current;
    if (track == null) return;

    if (_supportsBackgroundPlayback) {
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.file(track.filePath),
          tag: MediaItem(
            id: track.filePath,
            title: track.title,
            artist: track.artist,
            album: track.album,
            duration: track.duration == Duration.zero ? null : track.duration,
          ),
        ),
      );
    } else {
      await _player.setFilePath(track.filePath);
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  /// User-initiated skip forward. Logs the OLD track (by actual position
  /// reached, subject to the 30s threshold) before switching.
  Future<void> next() async {
    if (_currentIndex < _queue.length - 1) {
      _logCurrentListen(completedNaturally: false);
      _currentIndex++;
      await _loadCurrent();
      await _player.play();
    }
  }

  /// User-initiated skip backward. Same logging rules as next().
  Future<void> previous() async {
    if (_currentIndex > 0) {
      _logCurrentListen(completedNaturally: false);
      _currentIndex--;
      await _loadCurrent();
      await _player.play();
    }
  }

  /// Internal-only advance used after a track finishes on its own.
  /// Deliberately does NOT call _logCurrentListen() — the completion
  /// handler above already logged it, with the correct "full length"
  /// semantics. Logging here too would double-count every completed track.
  Future<void> _advanceAfterCompletion() async {
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      await _loadCurrent();
      await _player.play();
    }
    // If this was the last track in the queue, playback simply stops —
    // no wraparound, nothing further to log.
  }

  Future<void> seek(Duration position) => _player.seek(position);

  /// The single place listening time gets recorded. Two distinct modes:
  ///
  /// - completedNaturally: true  → the track played to the end on its
  ///   own. Always logs the FULL track length, with no threshold — even
  ///   a track shorter than 30 seconds counts if it played in full.
  ///
  /// - completedNaturally: false → the user skipped/switched away mid
  ///   track. Logs exactly how far the playhead got (_player.position,
  ///   not wall-clock time — immune to pauses/buffering skewing the
  ///   number), and only counts if that's 30 seconds or more.
  void _logCurrentListen({required bool completedNaturally}) {
    final track = current;
    if (track == null) return;

    final Duration listened;
    if (completedNaturally) {
      final playerDuration = _player.duration;
      listened = (playerDuration != null && playerDuration > Duration.zero)
          ? playerDuration
          : track.duration;
    } else {
      final pos = _player.position;
      final dur = _player.duration;
      // Defensive clamp: position should never exceed duration, but
      // guard against any rare floating-point/backend rounding blip.
      listened = (dur != null && dur > Duration.zero && pos > dur) ? dur : pos;
    }

    if (listened <= Duration.zero) return;
    if (!completedNaturally && listened < _kMinPartialListenThreshold) return;

    statsService.logListen(track, listened);
  }

  @override
  void dispose() {
    // App closing mid-track is the same as a manual skip — same rules.
    _logCurrentListen(completedNaturally: false);
    _player.dispose();
    super.dispose();
  }
}