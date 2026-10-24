import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/playlist.dart';
import 'playlist_service.dart';
import 'secure_token_store.dart';
import 'server_config.dart';

/// Reads back the playlists the server holds for her and merges them into
/// the ones on this device, so a playlist made on her phone shows up on her
/// computer (and the other way round, through PlaylistReporter).
///
/// It reads once at the start, again each time the app comes back to the
/// front or a token is saved, and every few minutes while the app is open.
/// It only ever adds or updates what the merge allows (see
/// PlaylistService.mergeRemote), it never throws, and a failure is never
/// shown to her.
class PlaylistPuller {
  PlaylistPuller({
    required ServerConfig config,
    required TokenStore tokenStore,
    required PlaylistService playlists,
    http.Client? client,
    Duration every = const Duration(minutes: 3),
  })  : _config = config,
        _tokenStore = tokenStore,
        _playlists = playlists,
        _client = client ?? http.Client(),
        _every = every;

  static const _timeout = Duration(seconds: 20);

  final ServerConfig _config;
  final TokenStore _tokenStore;
  final PlaylistService _playlists;
  final http.Client _client;
  final Duration _every;

  Timer? _timer;
  bool _started = false;
  bool _pulling = false;

  /// Reads now, and then every few minutes.
  void start() {
    if (_started) return;
    _started = true;
    unawaited(pullNow());
    _timer = Timer.periodic(_every, (_) => unawaited(pullNow()));
  }

  /// Something worth reading for has happened (a token was saved, the app
  /// came back to the front).
  void poke() => unawaited(pullNow());

  void dispose() => _timer?.cancel();

  /// Reads and merges once. True when the server answered and its playlists
  /// were taken in (even when nothing needed to change).
  Future<bool> pullNow() async {
    if (_pulling) return false;
    _pulling = true;
    try {
      final token = await _tokenStore.readToken();
      if (token == null || token.trim().isEmpty) return false;

      final response = await _client.get(_config.playlistsUri,
          headers: {'X-Token': token.trim()}).timeout(_timeout);
      if (response.statusCode != 200) return false;

      // Read as UTF-8 whatever the server says, so names in any script
      // arrive whole.
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map || decoded['playlists'] is! List) return false;
      final remote = [
        for (final entry in decoded['playlists'] as List)
          Playlist.tryParse(entry),
      ].whereType<Playlist>().toList();
      _playlists.mergeRemote(remote);
      return true;
    } catch (error) {
      debugPrint('Playlists not read: ${error.runtimeType}');
      return false;
    } finally {
      _pulling = false;
    }
  }
}
