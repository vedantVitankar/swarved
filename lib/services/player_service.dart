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

class PlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final StatsService statsService;

  List<Track> _queue = [];
  int _currentIndex = -1;
  DateTime? _currentTrackStartedAt;

  PlayerService(this.statsService) {
    _player.playerStateStream.listen((_) => notifyListeners());
    _player.positionStream.listen((_) => notifyListeners());

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _logCurrentListen();
        next();
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
    _logCurrentListen();
    _queue = tracks;
    _currentIndex = startIndex;
    await _loadCurrent();
    await _player.play();
  }

  Future<void> _loadCurrent() async {
    final track = current;
    if (track == null) return;

    if (_supportsBackgroundPlayback) {
      // just_audio_background requires a MediaItem tag on every source —
      // it's how the lock-screen/notification knows what's playing.
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
      // Windows/Linux: no background service involved, plain file load.
      await _player.setFilePath(track.filePath);
    }

    _currentTrackStartedAt = DateTime.now();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> next() async {
    if (_currentIndex < _queue.length - 1) {
      _logCurrentListen();
      _currentIndex++;
      await _loadCurrent();
      await _player.play();
    }
  }

  Future<void> previous() async {
    if (_currentIndex > 0) {
      _logCurrentListen();
      _currentIndex--;
      await _loadCurrent();
      await _player.play();
    }
  }

  Future<void> seek(Duration position) => _player.seek(position);

  void _logCurrentListen() {
    final track = current;
    final startedAt = _currentTrackStartedAt;
    if (track == null || startedAt == null) return;
    final listened = DateTime.now().difference(startedAt);
    if (listened.inSeconds < 3) return; // ignore accidental skips
    statsService.logListen(track, listened);
  }

  @override
  void dispose() {
    _logCurrentListen();
    _player.dispose();
    super.dispose();
  }
}