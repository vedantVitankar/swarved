import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smtc_windows/smtc_windows.dart';

import 'system_media_controls.dart';

/// The Windows media overlay (System Media Transport Controls): the panel the
/// keyboard's media keys bring up, with the song, its cover and the buttons.
/// Only ever created on Windows.
class SmtcWindowsSession implements SystemMediaSession {
  SmtcWindowsSession._(this._smtc);

  final SMTCWindows _smtc;

  /// Debug runs only: says in the console what the overlay was asked to do,
  /// so a missing overlay can be told apart from a missing call.
  static void _log(String message) {
    if (kDebugMode) debugPrint('[overlay] $message');
  }

  /// Opens the overlay, or null when it cannot be had. Never throws, so a
  /// problem here costs the overlay and nothing else.
  static Future<SmtcWindowsSession?> start() async {
    try {
      await SMTCWindows.initialize();
      final smtc = SMTCWindows(
        config: const SMTCConfig(
          playEnabled: true,
          pauseEnabled: true,
          nextEnabled: true,
          prevEnabled: true,
          stopEnabled: false,
          fastForwardEnabled: false,
          rewindEnabled: false,
        ),
        status: PlaybackStatus.stopped,
      );
      _log('started');
      return SmtcWindowsSession._(smtc);
    } catch (error) {
      debugPrint('Windows media overlay not started: $error');
      return null;
    }
  }

  @override
  Stream<MediaButton> get buttons => _smtc.buttonPressStream
      .map(_button)
      .where((button) => button != null)
      .map((button) => button!);

  static MediaButton? _button(PressedButton pressed) {
    _log('button pressed: ${pressed.name}');
    return switch (pressed) {
      PressedButton.play => MediaButton.play,
      PressedButton.pause => MediaButton.pause,
      PressedButton.next => MediaButton.next,
      PressedButton.previous => MediaButton.previous,
      _ => null,
    };
  }

  @override
  Future<void> show({
    required String title,
    required String artist,
    String? album,
    String? thumbnail,
  }) async {
    _log('show "$title" by "$artist" cover: ${thumbnail ?? 'none'}');
    // Windows keeps the old picture when a new one is not given, so a song
    // without a cover would wear the previous song's.
    if (thumbnail == null) await _smtc.clearMetadata();
    await _smtc.updateMetadata(
      MusicMetadata(
        title: title,
        artist: artist,
        album: album,
        thumbnail: thumbnail,
      ),
    );
  }

  @override
  Future<void> setStatus(SessionStatus status) {
    _log('status: ${status.name}');
    return _smtc.setPlaybackStatus(
      switch (status) {
        SessionStatus.stopped => PlaybackStatus.stopped,
        SessionStatus.changing => PlaybackStatus.changing,
        SessionStatus.playing => PlaybackStatus.playing,
        SessionStatus.paused => PlaybackStatus.paused,
      },
    );
  }

  @override
  Future<void> setTimeline({
    required Duration position,
    required Duration duration,
  }) {
    _log('timeline: ${position.inSeconds}s of ${duration.inSeconds}s');
    return _smtc.updateTimeline(
      PlaybackTimeline(
        startTimeMs: 0,
        endTimeMs: duration.inMilliseconds,
        positionMs: position.inMilliseconds,
      ),
    );
  }

  @override
  Future<void> setButtons({required bool next, required bool previous}) async {
    _log('buttons: next=$next previous=$previous');
    await _smtc.setIsNextEnabled(next);
    await _smtc.setIsPrevEnabled(previous);
  }

  @override
  Future<void> dispose() => _smtc.dispose();
}
