import 'dart:async';

import 'package:flutter/foundation.dart';

import '../content/words.dart';
import '../models/track.dart';

/// A button on the operating system's media overlay (the one the keyboard's
/// media keys bring up), or on a keyboard or headset.
enum MediaButton { play, pause, next, previous }

/// What the overlay shows next to the controls.
enum SessionStatus { stopped, changing, playing, paused }

/// What [SystemMediaControls] needs to read from, and press on, the player.
/// PlayerService is the real one; tests use a small stand-in.
abstract interface class MediaSessionPlayer implements Listenable {
  Track? get current;
  bool get isInterlude;
  bool get isPlaying;
  bool get isLoading;
  bool get canGoNext;
  Duration get position;
  Duration get duration;

  Future<void> togglePlayPause();
  Future<void> next();
  Future<void> restartOrPrevious();
}

/// The operating system's media overlay, however it is reached. On Windows
/// this is SmtcWindowsSession; tests use a fake. Every method may fail, and
/// [SystemMediaControls] never lets that reach the player.
abstract interface class SystemMediaSession {
  Stream<MediaButton> get buttons;

  /// Shows [title] and [artist] with [thumbnail] (a web address or a file
  /// address, never anything else). A null [thumbnail] means no picture,
  /// and the previous song's picture must go.
  Future<void> show({
    required String title,
    required String artist,
    String? album,
    String? thumbnail,
  });

  Future<void> setStatus(SessionStatus status);
  Future<void> setTimeline({
    required Duration position,
    required Duration duration,
  });
  Future<void> setButtons({required bool next, required bool previous});
  Future<void> dispose();
}

/// A cover for a song that has none on the web: the address of a file on this
/// computer, or null.
typedef LocalArtwork = Future<String?> Function(Track track);

/// Keeps the operating system's media overlay in step with the player: which
/// song, whether it plays, how far it has got, and which buttons work. And
/// the other way round: a media key or an overlay button does what the same
/// button in the app does.
///
/// It never throws and never waits on the overlay, so music is never held up
/// by it.
class SystemMediaControls {
  SystemMediaControls({
    required SystemMediaSession session,
    LocalArtwork? localArtwork,
    DateTime Function()? clock,
  })  : _session = session,
        _localArtwork = localArtwork,
        _clock = clock ?? DateTime.now;

  /// The position has to be this far from where the overlay would have
  /// counted it to, before it is told again. Smaller than any real seek,
  /// bigger than the jitter in the player's own reports.
  static const _seekMargin = Duration(seconds: 2);

  final SystemMediaSession _session;
  final LocalArtwork? _localArtwork;
  final DateTime Function() _clock;

  MediaSessionPlayer? _player;
  StreamSubscription<MediaButton>? _buttons;

  // What the overlay was last told.
  String? _face;
  SessionStatus? _status;
  bool? _next;
  Duration? _duration;
  Duration _anchor = Duration.zero;
  DateTime _anchorAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _anchorMoves = false;

  // One update at a time, in the order they were decided.
  Future<void> _busy = Future<void>.value();

  /// Starts following [player]. Call once.
  void attach(MediaSessionPlayer player) {
    if (_player != null) return;
    _player = player;
    if (kDebugMode) debugPrint('[overlay] attached to the player');
    _buttons = _session.buttons.listen(_pressed, onError: (Object error) {
      debugPrint('Media button ignored: $error');
    });
    player.addListener(_changed);
    _changed();
  }

  Future<void> dispose() async {
    _player?.removeListener(_changed);
    _player = null;
    await _buttons?.cancel();
    try {
      await _session.dispose();
    } catch (error) {
      debugPrint('Media overlay not closed: $error');
    }
  }

  // ---- player -> overlay ---------------------------------------------------

  void _changed() {
    final player = _player;
    if (player == null) return;
    try {
      _decide(player);
    } catch (error) {
      debugPrint('Media overlay not updated: $error');
    }
  }

  void _decide(MediaSessionPlayer player) {
    final track = player.current;
    final interlude = player.isInterlude;
    final face = track == null ? null : (interlude ? 'voice' : track.id);
    final status = _statusOf(player, track);
    final next = player.canGoNext;
    final duration = _durationOf(player, track);
    final position = player.position;
    final now = _clock();

    final jobs = <Future<void> Function()>[];

    final faceChanged = face != _face;
    if (faceChanged && track != null) {
      jobs.add(() => _show(track, interlude));
    }
    if (next != _next || faceChanged) {
      jobs.add(() => _session.setButtons(next: next, previous: true));
    }

    final statusChanged = status != _status;
    final durationChanged = duration != _duration;
    if (faceChanged ||
        statusChanged ||
        durationChanged ||
        _strayed(position, now)) {
      _anchor = position;
      _anchorAt = now;
      _anchorMoves = status == SessionStatus.playing;
      final end = duration;
      final at = end > Duration.zero && position > end ? end : position;
      jobs.add(() => _session.setTimeline(position: at, duration: end));
    }
    if (statusChanged || faceChanged) {
      jobs.add(() => _session.setStatus(status));
    }

    _face = face;
    _status = status;
    _next = next;
    _duration = duration;
    if (jobs.isEmpty) return;

    _busy = _busy.then((_) async {
      for (final job in jobs) {
        try {
          await job();
        } catch (error) {
          debugPrint('Media overlay not updated: $error');
        }
      }
    });
  }

  SessionStatus _statusOf(MediaSessionPlayer player, Track? track) {
    if (track == null) return SessionStatus.stopped;
    if (player.isLoading) return SessionStatus.changing;
    return player.isPlaying ? SessionStatus.playing : SessionStatus.paused;
  }

  Duration _durationOf(MediaSessionPlayer player, Track? track) {
    if (player.isInterlude) return player.duration;
    final known = player.duration;
    if (known > Duration.zero) return known;
    return track?.duration ?? Duration.zero;
  }

  /// The overlay counts the position on by itself while a song plays, so it
  /// only needs telling when the real position is somewhere else: a seek.
  bool _strayed(Duration position, DateTime now) {
    final since = _anchorMoves ? now.difference(_anchorAt) : Duration.zero;
    final expected = _anchor + since;
    return (position - expected).abs() > _seekMargin;
  }

  Future<void> _show(Track track, bool interlude) async {
    if (interlude) {
      // His recording: his words, no song, no picture.
      await _session.show(
        title: Words.voiceBreakTitle,
        artist: Words.voiceBreakFrom,
      );
      return;
    }
    var art = webAddress(track.artworkUrl);
    final localArtwork = _localArtwork;
    if (art == null && localArtwork != null) {
      try {
        art = fileAddress(await localArtwork(track));
      } catch (error) {
        debugPrint('Cover not prepared for the overlay: $error');
      }
    }
    await _session.show(
      title: track.title,
      artist: track.artist,
      album: track.album.isEmpty ? null : track.album,
      thumbnail: art,
    );
  }

  /// [url] when it is an absolute http or https address, otherwise null. The
  /// native side cannot cope with anything else, so nothing else is passed.
  @visibleForTesting
  static String? webAddress(String? url) {
    if (url == null) return null;
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.isAbsolute || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri.toString();
  }

  /// [url] when it is an absolute file address, otherwise null.
  @visibleForTesting
  static String? fileAddress(String? url) {
    if (url == null) return null;
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.scheme != 'file' || uri.path.isEmpty) return null;
    return uri.toString();
  }

  // ---- overlay -> player ---------------------------------------------------

  void _pressed(MediaButton button) {
    final player = _player;
    if (player == null) return;
    switch (button) {
      // The keyboard's one play/pause key arrives as whichever the overlay
      // thinks is next; the player's own state decides what is really needed.
      case MediaButton.play:
        if (!player.isPlaying) _run(player.togglePlayPause);
      case MediaButton.pause:
        if (player.isPlaying) _run(player.togglePlayPause);
      case MediaButton.next:
        _run(player.next);
      case MediaButton.previous:
        _run(player.restartOrPrevious);
    }
  }

  void _run(Future<void> Function() action) {
    unawaited(() async {
      try {
        await action();
      } catch (error) {
        debugPrint('Media button failed: $error');
      }
    }());
  }
}
