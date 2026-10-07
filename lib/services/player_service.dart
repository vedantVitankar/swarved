import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import '../utils/queue_order.dart';
import '../utils/volume_level.dart';
import 'stats_service.dart';
import 'stream_endpoint.dart';

/// just_audio_background (and the MediaItem tag it requires) only works
/// on Android, iOS, and macOS — audio_service doesn't support Windows or
/// Linux. This must match the same check in main.dart.
bool get _supportsBackgroundPlayback =>
    Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

const _kVolumeKey = 'player_volume_v1';

/// A manual skip/switch only counts toward listening stats once the user
/// has actually heard at least this much of the track. A natural full
/// completion always counts in full, regardless of this threshold (see
/// _logCurrentListen below) — a 10-second jingle that plays to the end
/// should still count, even though it's under 30 seconds.
const _kMinPartialListenThreshold = Duration(seconds: 30);

/// Pressing "previous" restarts the current song if more than this much of
/// it has played, and only goes back a song when you're near its start.
const _kRestartThreshold = Duration(seconds: 3);

class PlayerService extends ChangeNotifier {
  /// Request headers go straight to the platform's own player instead of
  /// through just_audio's local cleartext proxy. YouTube songs need the
  /// X-Token header, and the app only ever talks HTTPS.
  final AudioPlayer _player = AudioPlayer(useProxyForRequestHeaders: false);
  final StatsService statsService;
  final StreamEndpoint _streams;

  /// Which song follows which. Shuffle and repeat rules live here, so this
  /// service only has to ask "what's next?".
  final QueueOrder _order = QueueOrder();

  List<Track> _queue = [];
  int _currentIndex = -1;

  /// The id of the song the player actually holds. Null while a song is
  /// still loading or failed to load, so listening time is never credited to
  /// a song the player isn't playing.
  String? _loadedId;

  double _volume = VolumeLevel.defaultLevel;

  /// The level before mute, so unmuting goes back where the listener was.
  double _premuteVolume = VolumeLevel.defaultLevel;

  PlayerService(this.statsService, this._streams) {
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

    _loadVolume();
  }

  Track? get current => _currentIndex >= 0 && _currentIndex < _queue.length
      ? _queue[_currentIndex]
      : null;

  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration get bufferedPosition => _player.bufferedPosition;
  Duration get duration => _player.duration ?? Duration.zero;

  /// Current volume in [0.0, 1.0]. Zero means muted via the toggle.
  double get volume => _volume;

  bool get shuffle => _order.shuffle;
  QueueRepeat get repeat => _order.repeat;

  /// Whether a next / previous song exists right now (it depends on
  /// shuffle and repeat), for the swipe and the skip buttons.
  bool get canGoNext => _order.hasNext;
  bool get canGoPrevious => _order.hasPrevious;

  Future<void> playQueue(List<Track> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) return;
    _logCurrentListen(completedNaturally: false);
    _queue = tracks;
    _order.start(length: tracks.length, startIndex: startIndex);
    _currentIndex = _order.currentIndex ?? 0;
    if (await _loadCurrent()) await _player.play();
  }

  /// Loads the current song into the player. Returns false when it could
  /// not be loaded, so the caller doesn't start playback.
  Future<bool> _loadCurrent() async {
    final track = current;
    if (track == null) return false;

    _loadedId = null;
    final loaded =
        track.isLocal ? await _loadLocal(track) : await _loadRemote(track);

    // Another song may have been chosen while this one was loading.
    if (!loaded || !identical(track, current)) return false;
    _loadedId = track.id;
    return true;
  }

  Future<bool> _loadLocal(Track track) async {
    if (_supportsBackgroundPlayback) {
      await _player.setAudioSource(
        AudioSource.uri(Uri.file(track.filePath), tag: _mediaItem(track)),
      );
    } else {
      await _player.setFilePath(track.filePath);
    }
    return true;
  }

  /// Streams a YouTube song from the SwarVed server. The player sends the
  /// token itself, so the audio never has to touch the app's own code.
  Future<bool> _loadRemote(Track track) async {
    final stream = await _streams.requestFor(track);
    if (stream == null) {
      debugPrint('No stream address for ${track.id} (is a token saved?)');
      return false;
    }

    try {
      await _player.setAudioSource(
        AudioSource.uri(
          stream.uri,
          headers: stream.headers,
          tag: _supportsBackgroundPlayback ? _mediaItem(track) : null,
        ),
      );
      return true;
    } on PlayerInterruptedException {
      return false; // a newer song was chosen while this one was loading
    } catch (e) {
      debugPrint('Could not stream ${track.id}: $e');
      return false;
    }
  }

  MediaItem _mediaItem(Track track) {
    final art = track.artworkUrl;
    return MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      album: track.album.isEmpty ? null : track.album,
      duration: track.duration == Duration.zero ? null : track.duration,
      artUri: art == null ? null : Uri.tryParse(art),
    );
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
    final index = _order.advance();
    if (index == null) return;
    _logCurrentListen(completedNaturally: false);
    await _switchTo(index);
  }

  /// User-initiated skip backward: always the previous song. Used by the
  /// swipe. Same logging rules as next().
  Future<void> previous() async {
    final index = _order.back();
    if (index == null) return;
    _logCurrentListen(completedNaturally: false);
    await _switchTo(index);
  }

  /// What a "previous" button does: restart the song if it has been
  /// playing for a while, otherwise go back one song.
  Future<void> restartOrPrevious() async {
    if (_player.position > _kRestartThreshold || !_order.hasPrevious) {
      await _player.seek(Duration.zero);
      return;
    }
    await previous();
  }

  void toggleShuffle() {
    _order.setShuffle(!_order.shuffle);
    notifyListeners();
  }

  /// Off, then all, then one, then off again.
  void cycleRepeat() {
    _order.repeat = switch (_order.repeat) {
      QueueRepeat.off => QueueRepeat.all,
      QueueRepeat.all => QueueRepeat.one,
      QueueRepeat.one => QueueRepeat.off,
    };
    notifyListeners();
  }

  Future<void> _switchTo(int index) async {
    _currentIndex = index;
    if (await _loadCurrent()) await _player.play();
  }

  /// Internal-only advance used after a track finishes on its own.
  /// Deliberately does NOT call _logCurrentListen() — the completion
  /// handler above already logged it, with the correct "full length"
  /// semantics. Logging here too would double-count every completed track.
  Future<void> _advanceAfterCompletion() async {
    final index = _order.onSongEnded();
    // Nothing after the last song (and no repeat): playback simply stops.
    if (index == null) return;
    await _switchTo(index);
  }

  Future<void> seek(Duration position) => _player.seek(position);

  /// Sets the volume and persists it. Dragging the slider to zero is treated
  /// as an implicit mute — the premute memory is only updated for non-zero
  /// values, so unmuting after a drag-to-zero still restores a sensible level.
  Future<void> setVolume(double level) async {
    final clamped = VolumeLevel.clamp(level);
    if (clamped > VolumeLevel.min) _premuteVolume = clamped;
    _volume = clamped;
    await _player.setVolume(clamped);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kVolumeKey, clamped);
  }

  /// Mutes when audible, unmutes to the last remembered level when already
  /// muted. The remembered level is also saved so a cold restart unmutes
  /// to the right place.
  Future<void> toggleMute() async {
    final next = VolumeLevel.isMuted(_volume)
        ? VolumeLevel.unmutedLevel(_premuteVolume)
        : VolumeLevel.min;
    await setVolume(next);
  }

  /// Reads the saved volume from SharedPreferences and applies it.
  /// Called once from the constructor; the player defaults to 1.0 until
  /// this resolves, which is quick enough that the user never hears it.
  Future<void> _loadVolume() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_kVolumeKey);
    if (saved != null) {
      // Restore muted state too: if saved is 0 the slider shows 0,
      // but _premuteVolume stays at its default so unmuting works.
      _volume = VolumeLevel.clamp(saved);
      await _player.setVolume(_volume);
      notifyListeners();
    }
  }

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
    if (track == null || _loadedId != track.id) return;

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