import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/track.dart';
import 'player_service.dart';

/// What the welcome's song step needs from the player: to start the song,
/// pause it, and know whether it is playing. PlayerService is the real one
/// (see [PlayerSongPlayback]); tests use a small stand-in, because the real
/// one needs audio hardware.
abstract interface class SongPlayback implements Listenable {
  /// Whether any song is on, so the mini player is on screen.
  bool get hasSong;

  /// Whether [track] is the song on right now, and it is playing.
  bool isPlaying(Track track);

  /// Starts [track]; when it is already the song on, pauses or resumes it.
  void toggle(Track track);
}

/// The real player behind [SongPlayback].
class PlayerSongPlayback implements SongPlayback {
  PlayerSongPlayback(this._player);

  final PlayerService _player;

  @override
  bool get hasSong => _player.current != null;

  @override
  bool isPlaying(Track track) =>
      _player.current?.id == track.id && _player.isPlaying;

  @override
  void toggle(Track track) {
    if (_player.current?.id == track.id) {
      unawaited(_player.togglePlayPause());
    } else {
      unawaited(_player.playQueue([track]));
    }
  }

  @override
  void addListener(VoidCallback listener) => _player.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _player.removeListener(listener);
}
