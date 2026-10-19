import 'package:flutter/foundation.dart';

import '../models/track.dart';
import 'player_service.dart';
import 'system_media_controls.dart';

/// Lets [SystemMediaControls] read from and press buttons on the real player
/// without it knowing anything about the player's other workings.
class PlayerMediaSession implements MediaSessionPlayer {
  PlayerMediaSession(this._player);

  final PlayerService _player;

  @override
  Track? get current => _player.current;

  @override
  bool get isInterlude => _player.isInterlude;

  @override
  bool get isPlaying => _player.isPlaying;

  @override
  bool get isLoading => _player.isLoading;

  @override
  bool get canGoNext => _player.canGoNext;

  @override
  Duration get position => _player.position;

  @override
  Duration get duration => _player.duration;

  @override
  Future<void> togglePlayPause() => _player.togglePlayPause();

  @override
  Future<void> next() => _player.next();

  @override
  Future<void> restartOrPrevious() => _player.restartOrPrevious();

  @override
  void addListener(VoidCallback listener) => _player.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _player.removeListener(listener);
}
