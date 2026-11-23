import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'clip_engine.dart';

/// Where a letter's recording is, for the controls under the letter.
enum LetterVoicePhase {
  /// Not started yet, or taken over by a song.
  idle,

  /// Being fetched or opened.
  loading,
  playing,
  paused,

  /// The recording is not on this phone and could not be fetched.
  missing,

  /// It is here but would not play.
  failed,
}

/// Plays one letter's recording on its own: its own position, its own length,
/// its own play and pause. The music's queue is not involved, so nothing in
/// the main player is disturbed.
///
/// Starting it pauses the music. When the recording ends, or the controller
/// is disposed (the letter is closed), the music stays paused until she
/// presses play herself.
class LetterVoiceController extends ChangeNotifier {
  final ClipEngine engine;

  /// Gets the recording's file, downloading it first if need be. Null when it
  /// cannot be had.
  final Future<File?> Function(String name) fetch;

  /// The recording's name on the server.
  final String file;

  /// What the phone's media notification shows while it plays.
  final String title;
  final String artist;

  LetterVoiceController({
    required this.engine,
    required this.fetch,
    required this.file,
    required this.title,
    required this.artist,
  });

  LetterVoicePhase _phase = LetterVoicePhase.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription<ClipStatus>? _sub;
  bool _disposed = false;

  /// True from asking the engine to open the clip until it is closed or
  /// taken, so [dispose] knows whether there is anything to give back.
  bool _holding = false;

  /// True while a finished recording is being wound back to the start, so
  /// the events on the way do not make it look as if it started again.
  bool _rewinding = false;

  /// Bumped for each start, so a start that was overtaken does nothing more.
  int _serial = 0;

  LetterVoicePhase get phase => _phase;
  Duration get position => _position;

  /// Zero until the recording has been opened.
  Duration get duration => _duration;
  bool get isPlaying => _phase == LetterVoicePhase.playing;
  bool get isLoading => _phase == LetterVoicePhase.loading;

  /// Whether the slider can be moved.
  bool get canSeek =>
      (_phase == LetterVoicePhase.playing ||
          _phase == LetterVoicePhase.paused) &&
      _duration > Duration.zero;

  /// The one button: starts, pauses or continues.
  Future<void> toggle() async {
    switch (_phase) {
      case LetterVoicePhase.loading:
        return;
      case LetterVoicePhase.playing:
        await _pause();
      case LetterVoicePhase.paused:
        await _continue();
      case LetterVoicePhase.idle:
      case LetterVoicePhase.missing:
      case LetterVoicePhase.failed:
        await _start();
    }
  }

  Future<void> seek(Duration to) async {
    if (!canSeek) return;
    final clamped = to < Duration.zero
        ? Duration.zero
        : (to > _duration ? _duration : to);
    _position = clamped;
    _changed();
    try {
      await engine.seekClip(clamped);
    } catch (error) {
      debugPrint('Letter recording not moved: $error');
    }
  }

  Future<void> _start() async {
    final serial = ++_serial;
    _phase = LetterVoicePhase.loading;
    _position = Duration.zero;
    _changed();

    File? recording;
    try {
      recording = await fetch(file);
    } catch (error) {
      debugPrint('Letter recording not fetched: $error');
    }
    if (_disposed || serial != _serial) return;
    if (recording == null) {
      _phase = LetterVoicePhase.missing;
      _changed();
      return;
    }

    _sub ??= engine.clipStatus.listen(_onStatus);
    _holding = true;
    try {
      await engine.openClip(recording, title: title, artist: artist);
      // Closed, or taken by a song, while it was opening.
      if (_disposed || serial != _serial || !_holding) return;
      await engine.playClip();
    } catch (error) {
      debugPrint('Letter recording not played: $error');
      if (_disposed || serial != _serial || !_holding) return;
      _holding = false;
      _phase = LetterVoicePhase.failed;
      _changed();
      unawaited(_giveBack());
      return;
    }
    if (_disposed || serial != _serial || !_holding) return;
    _phase = LetterVoicePhase.playing;
    _changed();
  }

  Future<void> _pause() async {
    _phase = LetterVoicePhase.paused;
    _changed();
    try {
      await engine.pauseClip();
    } catch (error) {
      debugPrint('Letter recording not paused: $error');
    }
  }

  Future<void> _continue() async {
    _phase = LetterVoicePhase.playing;
    _changed();
    try {
      await engine.playClip();
    } catch (error) {
      debugPrint('Letter recording not continued: $error');
    }
  }

  void _onStatus(ClipStatus status) {
    if (_disposed) return;
    switch (status.end) {
      case ClipEnd.taken:
        // A song started on the audio player: this recording is gone.
        _holding = false;
        _rewinding = false;
        _phase = LetterVoicePhase.idle;
        _position = Duration.zero;
        _changed();
        return;
      case ClipEnd.finished:
        if (_rewinding) return;
        if (status.duration > Duration.zero) _duration = status.duration;
        // Back to the start and paused, so a second press plays it again.
        // The music is not touched: it stays paused.
        _phase = LetterVoicePhase.paused;
        _position = Duration.zero;
        _changed();
        unawaited(_rewind());
        return;
      case ClipEnd.none:
        break;
    }
    if (_rewinding) return;
    if (_phase != LetterVoicePhase.playing &&
        _phase != LetterVoicePhase.paused) {
      // Still opening: the length is useful, nothing else is.
      if (status.duration > Duration.zero && status.duration != _duration) {
        _duration = status.duration;
        _changed();
      }
      return;
    }
    _position = status.position;
    if (status.duration > Duration.zero) _duration = status.duration;
    _phase =
        status.playing ? LetterVoicePhase.playing : LetterVoicePhase.paused;
    _changed();
  }

  /// After the end: stop it playing and go back to the first second.
  Future<void> _rewind() async {
    _rewinding = true;
    try {
      await engine.pauseClip();
      await engine.seekClip(Duration.zero);
    } catch (error) {
      debugPrint('Letter recording not wound back: $error');
    } finally {
      _rewinding = false;
    }
  }

  Future<void> _giveBack() async {
    try {
      await engine.closeClip();
    } catch (error) {
      debugPrint('Audio player not given back: $error');
    }
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  /// Closing the letter stops its recording. The music stays paused.
  @override
  void dispose() {
    _disposed = true;
    _serial++;
    unawaited(_sub?.cancel());
    if (_holding) {
      _holding = false;
      unawaited(_giveBack());
    }
    super.dispose();
  }
}
