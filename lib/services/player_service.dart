import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../content/words.dart';
import '../models/play_source.dart';
import '../models/playback_problem.dart';
import '../models/track.dart';
import '../utils/played_point.dart';
import '../utils/stall_detector.dart';
import '../utils/queue_order.dart';
import '../utils/volume_level.dart';
import 'stats_service.dart';
import 'queue_prefetcher.dart';
import 'stream_endpoint.dart';
import 'voice_service.dart';

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

/// How long the player gets to open a stream the server has already vouched
/// for, before the song is given up on.
const _kLoadTimeout = Duration(seconds: 20);

/// How many times a YouTube song whose stream drops part-way is quietly
/// asked for again, from where it stopped, before the listener is told.
const _kMaxAutoRetries = 3;

/// A stream that ends this much before the song's length has been cut short,
/// not finished.
const _kEarlyEndMargin = Duration(seconds: 8);

/// Once a retried song has played this much further, the next drop gets a
/// fresh set of retries.
const _kRetryRecovered = Duration(seconds: 20);

/// How often the player is checked for a song that has stood still.
const _kWatchdogEvery = Duration(seconds: 2);

/// A song this close to its end is allowed to stand still: it is finishing.
const _kNearTheEnd = Duration(seconds: 3);

/// Pressing "previous" restarts the current song if more than this much of
/// it has played, and only goes back a song when you're near its start.
const _kRestartThreshold = Duration(seconds: 3);

/// How one attempt to load a song went.
class _LoadResult {
  const _LoadResult.ok()
      : ok = true,
        problem = null;

  /// Not loaded, but nothing to tell the listener: a newer song took over.
  const _LoadResult.skipped()
      : ok = false,
        problem = null;

  const _LoadResult.failed(PlaybackProblem this.problem) : ok = false;

  final bool ok;
  final PlaybackProblem? problem;
}

class PlayerService extends ChangeNotifier {
  /// Request headers go straight to the platform's own player instead of
  /// through just_audio's local cleartext proxy. YouTube songs need the
  /// X-Token header, and the app only ever talks HTTPS.
  final AudioPlayer _player = AudioPlayer(useProxyForRequestHeaders: false);
  final StatsService statsService;
  final StreamEndpoint _streams;

  /// Asks the server to download the next song while this one plays.
  /// Optional, so nothing else about the player depends on it.
  final QueuePrefetcher? _prefetcher;

  /// Says whether one of his recordings plays between two songs. Optional.
  final VoiceInterludeService? _voices;

  /// True while a recording of his plays between two songs. [current] is
  /// already the song that follows it.
  bool _interlude = false;

  /// Which song follows which. Shuffle and repeat rules live here, so this
  /// service only has to ask "what's next?".
  final QueueOrder _order = QueueOrder();

  List<Track> _queue = [];
  int _currentIndex = -1;

  /// Where the queue came from (a playlist), for "Playing from ...". Null
  /// for a folder or a search, which Now Playing words from the song itself.
  PlaySource? _source;

  final math.Random _random = math.Random();

  /// The id of the song the player actually holds. Null while a song is
  /// still loading or failed to load, so listening time is never credited to
  /// a song the player isn't playing.
  String? _loadedId;

  /// True from tapping a YouTube song until it is loaded. Local songs load
  /// too fast to be worth showing, so they never set it.
  bool _loading = false;

  /// Bumped by every load. A load that finishes under an older number was
  /// replaced by a newer song, and must not touch the state.
  int _loadSerial = 0;

  PlaybackProblem? _problem;

  /// Where a song was when its connection dropped, so retry can resume there.
  Duration? _resumeAt;

  /// Quiet retries used on the current song, the pause before the next one,
  /// and where the song was when the last one was scheduled.
  int _autoRetries = 0;
  Timer? _retryTimer;
  Duration _retryPoint = Duration.zero;

  /// How far into the song the listener got. The player itself reads zero
  /// once a song has ended, so this is what says whether it really ended.
  final PlayedPoint _played = PlayedPoint();

  /// Notices a stream that was cut without the player saying so.
  final StallDetector _stalls = StallDetector();
  Timer? _watchdog;
  String _lastStateNote = '';

  double _volume = VolumeLevel.defaultLevel;

  /// The level before mute, so unmuting goes back where the listener was.
  double _premuteVolume = VolumeLevel.defaultLevel;

  PlayerService(
    this.statsService,
    this._streams, {
    QueuePrefetcher? prefetcher,
    VoiceInterludeService? voices,
  })  : _prefetcher = prefetcher,
        _voices = voices {
    _player.playerStateStream
        .listen((_) => notifyListeners(), onError: _onPlaybackError);
    _player.playbackEventStream.listen((_) {}, onError: _onPlaybackError);
    _player.positionStream.listen((position) {
      _played.see(position);
      if (_autoRetries > 0 && position - _retryPoint > _kRetryRecovered) {
        _autoRetries = 0; // it has been playing fine again
      }
      notifyListeners();
    });

    // Leave a trail in the log of what the player reports, so a song that
    // stops for no visible reason can be explained afterwards.
    _player.playerStateStream.listen((state) {
      final note = 'playing=${state.playing}, ${state.processingState.name}';
      if (note == _lastStateNote) return;
      _lastStateNote = note;
      debugPrint('Player: $note at ${_player.position.inSeconds}s '
          '(${current?.id ?? 'nothing'})');
    });
    _watchdog = Timer.periodic(_kWatchdogEvery, (_) => _checkForStall());

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        // His recording ended: on to the song that was waiting for it.
        if (_interlude) {
          unawaited(_loadAndPlay());
          return;
        }
        // A stream the server cut short also "completes". That is a drop,
        // not the end of the song: ask again from the same place.
        final track = current;
        final reached = _played.at;
        if (track != null &&
            _endedEarly(track, reached) &&
            _tryAgainQuietly(track, reached)) {
          return;
        }
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

  /// One of his recordings is playing between two songs. [current] is
  /// already the song that follows it, so screens show his words instead of
  /// that song while this is true.
  bool get isInterlude => _interlude;

  /// Why the current song isn't playing, or null when nothing is wrong.
  PlaybackProblem? get problem => _problem;

  /// True while a YouTube song is being fetched, asked for again after a
  /// dropped connection, or the player is waiting for more of it to arrive.
  /// Never true for local songs.
  bool get isLoading {
    if (_problem != null) return false; // the message takes over
    if (_loading || _waitingToRetry) return true;
    final track = current;
    if (track == null || track.isLocal) return false;
    return switch (_player.processingState) {
      ProcessingState.loading || ProcessingState.buffering => true,
      _ => false,
    };
  }

  /// A dropped song is being asked for again in a moment (see
  /// [_tryAgainQuietly]). The play button shows it as loading.
  bool get _waitingToRetry => _retryTimer?.isActive ?? false;

  Duration get position => _player.position;
  Duration get bufferedPosition => _player.bufferedPosition;
  Duration get duration => _player.duration ?? Duration.zero;

  /// Current volume in [0.0, 1.0]. Zero means muted via the toggle.
  double get volume => _volume;

  bool get shuffle => _order.shuffle;
  QueueRepeat get repeat => _order.repeat;

  /// Whether a next / previous song exists right now (it depends on
  /// shuffle and repeat), for the swipe and the skip buttons.
  bool get canGoNext => _interlude || _order.hasNext;
  bool get canGoPrevious => _order.hasPrevious;

  /// Where the queue now playing came from, or null when it has no name.
  PlaySource? get source => _source;

  Future<void> playQueue(
    List<Track> tracks, {
    int startIndex = 0,
    PlaySource? source,
  }) async {
    if (tracks.isEmpty) return;
    _logCurrentListen(completedNaturally: false);
    _queue = tracks;
    _source = source;
    _order.start(length: tracks.length, startIndex: startIndex);
    _currentIndex = _order.currentIndex ?? 0;
    await _loadAndPlay();
  }

  /// Turns shuffle on and starts [tracks] from a random song.
  Future<void> playShuffled(List<Track> tracks, {PlaySource? source}) async {
    if (tracks.isEmpty) return;
    _order.setShuffle(true);
    await playQueue(
      tracks,
      startIndex: _random.nextInt(tracks.length),
      source: source,
    );
  }

  /// Loads the current song and starts it, keeping [isLoading] and
  /// [problem] up to date on the way. [resumeAt] picks a song up where a
  /// dropped connection left it.
  Future<void> _loadAndPlay({Duration? resumeAt}) async {
    final serial = ++_loadSerial;
    _interlude = false;
    _stalls.reset();
    _retryTimer?.cancel();
    _played.moveTo(resumeAt ?? Duration.zero);
    if (resumeAt == null) _autoRetries = 0; // a new song, or a manual retry
    _prefetcher?.cancel(); // a new song: the old "next" no longer applies
    final track = current;
    _problem = null;
    _resumeAt = null;
    _loading = track != null && !track.isLocal;
    notifyListeners();

    var result = const _LoadResult.skipped();
    try {
      result = await _loadCurrent();
    } finally {
      if (serial == _loadSerial) {
        _loading = false;
        _problem = result.problem;
        notifyListeners();
      }
    }

    if (serial != _loadSerial) return; // a newer song took over

    if (!result.ok) {
      // The song that was playing before must not carry on under a message
      // saying this one can't play.
      if (result.problem != null) await _player.stop();
      return;
    }

    _schedulePrefetch();
    if (resumeAt != null) await _player.seek(resumeAt);
    await _player.play();
  }

  /// Loads the current song into the player.
  Future<_LoadResult> _loadCurrent() async {
    final track = current;
    if (track == null) return const _LoadResult.skipped();

    _loadedId = null;
    final result =
        track.isLocal ? await _loadLocal(track) : await _loadRemote(track);

    // Another song may have been chosen while this one was loading.
    if (!identical(track, current)) return const _LoadResult.skipped();

    if (result.ok) _loadedId = track.id;
    return result;
  }

  Future<_LoadResult> _loadLocal(Track track) async {
    if (_supportsBackgroundPlayback) {
      await _player.setAudioSource(
        AudioSource.uri(Uri.file(track.filePath), tag: _mediaItem(track)),
      );
    } else {
      await _player.setFilePath(track.filePath);
    }
    return const _LoadResult.ok();
  }

  /// Streams a YouTube song from the SwarVed server. The server is asked
  /// first, so a problem can be named. After that the player sends the token
  /// itself, so the audio never has to touch the app's own code.
  Future<_LoadResult> _loadRemote(Track track) async {
    final outcome = await _streams.prepare(track);
    final StreamRequest stream;
    switch (outcome) {
      case StreamBlocked(:final problem):
        return _LoadResult.failed(problem);
      case StreamReady(:final request):
        stream = request;
    }

    try {
      await _player
          .setAudioSource(
            AudioSource.uri(
              stream.uri,
              headers: stream.headers,
              tag: _supportsBackgroundPlayback ? _mediaItem(track) : null,
            ),
          )
          .timeout(_kLoadTimeout);
      return const _LoadResult.ok();
    } on PlayerInterruptedException {
      return const _LoadResult.skipped(); // a newer song replaced this one
    } on TimeoutException {
      return const _LoadResult.failed(PlaybackProblem.timeout);
    } catch (e) {
      debugPrint('Could not stream ${track.id}: $e');
      return const _LoadResult.failed(PlaybackProblem.unexpected);
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

  /// Play/pause. When the current song has a problem, this is also the way
  /// to try it again, so no mini player needs a button of its own for that.
  Future<void> togglePlayPause() async {
    if (_loading || _waitingToRetry) return; // already working on it
    if (_problem != null) {
      await retry();
      return;
    }
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  /// Tries the current song again, from where it stopped if its connection
  /// dropped part-way through.
  Future<void> retry() async {
    if (current == null || _loading) return;
    await _loadAndPlay(resumeAt: _resumeAt);
  }

  /// User-initiated skip forward. Logs the OLD track (by actual position
  /// reached, subject to the 30s threshold) before switching.
  Future<void> next() async {
    if (_interlude) {
      await _loadAndPlay(); // skips the recording, on to the song after it
      return;
    }
    final index = _order.advance();
    if (index == null) return;
    _logCurrentListen(completedNaturally: false);
    await _switchTo(index);
  }

  /// User-initiated skip backward: always the previous song. Used by the
  /// swipe. Same logging rules as next().
  Future<void> previous() async {
    if (_interlude) {
      await _loadAndPlay();
      return;
    }
    final index = _order.back();
    if (index == null) return;
    _logCurrentListen(completedNaturally: false);
    await _switchTo(index);
  }

  /// What a "previous" button does: restart the song if it has been
  /// playing for a while, otherwise go back one song.
  Future<void> restartOrPrevious() async {
    if (_player.position > _kRestartThreshold || !_order.hasPrevious) {
      await seek(Duration.zero);
      return;
    }
    await previous();
  }

  void toggleShuffle() {
    _order.setShuffle(!_order.shuffle);
    notifyListeners();
    _schedulePrefetch(); // the next song may have changed
  }

  /// Off, then all, then one, then off again.
  void cycleRepeat() {
    _order.repeat = switch (_order.repeat) {
      QueueRepeat.off => QueueRepeat.all,
      QueueRepeat.all => QueueRepeat.one,
      QueueRepeat.one => QueueRepeat.off,
    };
    notifyListeners();
    _schedulePrefetch();
  }

  /// Lines up the server's download of the song after this one. Only while
  /// this one is really loaded, so a failed or loading song asks for nothing.
  void _schedulePrefetch() {
    if (_loading || _problem != null || current == null) return;
    _prefetcher?.schedule(_upcomingTrack());
  }

  /// The song a skip would go to, or null when there is none, it can't be
  /// known yet, or the listener is looping the current one.
  Track? _upcomingTrack() {
    if (_order.repeat == QueueRepeat.one) return null;
    final index = _order.upcomingIndex;
    if (index == null || index == _currentIndex || index >= _queue.length) {
      return null;
    }
    return _queue[index];
  }

  Future<void> _switchTo(int index) async {
    _currentIndex = index;
    await _loadAndPlay();
  }

  /// Internal-only advance used after a track finishes on its own.
  /// Deliberately does NOT call _logCurrentListen() — the completion
  /// handler above already logged it, with the correct "full length"
  /// semantics. Logging here too would double-count every completed track.
  Future<void> _advanceAfterCompletion() async {
    final serial = _loadSerial;
    final index = _order.onSongEnded();
    // Nothing after the last song (and no repeat): playback simply stops.
    if (index == null) return;

    // One of his recordings may come between the two songs. Never when the
    // same song is looping, and never for one that is not on the phone.
    final voice =
        _order.repeat == QueueRepeat.one ? null : await _voices?.afterSong();
    if (serial != _loadSerial) return; // she chose something meanwhile
    if (voice == null) {
      await _switchTo(index);
      return;
    }
    await _playInterlude(voice, upNext: index);
  }

  /// Plays his recording [voice], then (when it ends, see the completion
  /// handler) the song at [upNext]. Nothing is credited to listening stats
  /// and the song's own retry and stall rules stay out of it. If the
  /// recording cannot be played, the song simply starts.
  Future<void> _playInterlude(File voice, {required int upNext}) async {
    final serial = ++_loadSerial;
    _stalls.reset();
    _retryTimer?.cancel();
    _prefetcher?.cancel();
    _currentIndex = upNext;
    _loadedId = null;
    _played.moveTo(Duration.zero);
    _autoRetries = 0;
    _problem = null;
    _resumeAt = null;
    _loading = false;
    _interlude = true;
    notifyListeners();

    try {
      if (_supportsBackgroundPlayback) {
        await _player.setAudioSource(
          AudioSource.uri(Uri.file(voice.path), tag: _voiceItem()),
        );
      } else {
        await _player.setFilePath(voice.path);
      }
      if (serial != _loadSerial) return; // another song took over
      _prefetcher?.schedule(current); // the song that follows warms up now
      await _player.play();
    } catch (error) {
      debugPrint('Voice not played: $error');
      if (serial == _loadSerial) unawaited(_loadAndPlay());
    }
  }

  MediaItem _voiceItem() => const MediaItem(
        id: 'voice',
        title: Words.voiceBreakTitle,
        artist: Words.voiceBreakFrom,
      );

  Future<void> seek(Duration position) {
    _played.moveTo(position);
    return _player.seek(position);
  }

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

  /// The player reports a failure while a song is playing (the connection
  /// dropped, the server restarted). A failure while LOADING is reported by
  /// the load itself, so it is ignored here.
  void _onPlaybackError(Object error, [StackTrace? stackTrace]) {
    final track = current;
    if (_loading || track == null || _loadedId != track.id) return;

    debugPrint('Playback error on ${track.id}: $error');
    if (_tryAgainQuietly(track, _player.position)) return;
    _resumeAt = _player.position;
    _problem = track.isLocal
        ? PlaybackProblem.unexpected
        : PlaybackProblem.connectionLost;
    notifyListeners();
  }

  /// A YouTube song that is meant to be playing but has stopped moving: its
  /// connection was cut and the player never said. Treated like any other
  /// drop, so it is asked for again from the same place.
  void _checkForStall() {
    final track = current;
    final position = _player.position;
    final total = _player.duration ?? track?.duration ?? Duration.zero;
    final finishing = total > Duration.zero && position >= total - _kNearTheEnd;
    final stalled = _stalls.tick(
      position: position,
      expectingSound: track != null &&
          !track.isLocal &&
          !_loading &&
          _player.playing &&
          _player.processingState != ProcessingState.completed &&
          !finishing &&
          !(_retryTimer?.isActive ?? false),
      buffering: _player.processingState == ProcessingState.buffering,
      now: DateTime.now(),
    );
    if (stalled && track != null) {
      debugPrint('Playback of ${track.id} stood still at '
          '${position.inSeconds}s (${_player.processingState.name})');
      _onPlaybackError('the song stood still');
    }
  }

  /// Whether the stream of [track] stopped well before the song's length.
  /// [reached] is how far it got (see [_played]), never the player's own
  /// position, which is zero by the time a song has ended.
  bool _endedEarly(Track track, Duration reached) {
    if (track.isLocal) return false;
    return endedEarly(
      reached: reached,
      total: _player.duration ?? track.duration,
      margin: _kEarlyEndMargin,
    );
  }

  /// Asks for [track] again from [at] after a short pause (1, 2, then 4
  /// seconds), without telling the listener. False once it has been tried
  /// enough, or for a local song, so the caller does what it always did.
  bool _tryAgainQuietly(Track track, Duration at) {
    if (track.isLocal || _autoRetries >= _kMaxAutoRetries) return false;
    if (_retryTimer?.isActive ?? false) return true; // already on its way

    final wait = Duration(seconds: 1 << _autoRetries);
    _autoRetries++;
    _retryPoint = at;
    _resumeAt = at;
    debugPrint('Stream of ${track.id} dropped at ${at.inSeconds}s, '
        'trying again in ${wait.inSeconds}s ($_autoRetries of '
        '$_kMaxAutoRetries)');
    _retryTimer = Timer(wait, () {
      if (current?.id != track.id || _loading) return;
      unawaited(_loadAndPlay(resumeAt: at));
    });
    notifyListeners(); // the play button shows it is working on it
    return true;
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    _retryTimer?.cancel();
    _prefetcher?.dispose();
    // App closing mid-track is the same as a manual skip — same rules.
    _logCurrentListen(completedNaturally: false);
    _player.dispose();
    super.dispose();
  }
}
