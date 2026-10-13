import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/playlist.dart';
import 'playlist_service.dart';
import 'secure_token_store.dart';
import 'server_config.dart';

/// Tells the server what playlists she has, so he can see them (with each
/// song's link) in the admin site and write notes on her songs.
///
/// A one-way mirror: the server never sends playlists back, and nothing here
/// changes what she has. It sends a few seconds after the last change, only
/// when something is different from what was last sent, and tries again
/// later when the server could not be reached. It never throws, and a failure
/// is never shown to her.
class PlaylistReporter {
  PlaylistReporter({
    required ServerConfig config,
    required TokenStore tokenStore,
    required PlaylistService playlists,
    http.Client? client,
    Duration delay = const Duration(seconds: 5),
    Duration retryAfter = const Duration(minutes: 2),
  })  : _config = config,
        _tokenStore = tokenStore,
        _playlists = playlists,
        _client = client ?? http.Client(),
        _delay = delay,
        _retryAfter = retryAfter;

  static const _timeout = Duration(seconds: 20);

  final ServerConfig _config;
  final TokenStore _tokenStore;
  final PlaylistService _playlists;
  final http.Client _client;
  final Duration _delay;
  final Duration _retryAfter;

  Timer? _timer;
  bool _started = false;
  bool _sending = false;

  /// The body the server last accepted, so an unchanged list is not sent
  /// again.
  String? _lastSent;

  /// Starts watching her playlists, and sends once soon after the start.
  void start() {
    if (_started) return;
    _started = true;
    _playlists.addListener(_schedule);
    _schedule();
  }

  /// Something that was stopping a send has changed (a token was saved):
  /// try again soon.
  void poke() => _schedule();

  void dispose() {
    _timer?.cancel();
    _playlists.removeListener(_schedule);
  }

  void _schedule([Duration? after]) {
    _timer?.cancel();
    _timer = Timer(after ?? _delay, () => unawaited(reportNow()));
  }

  /// What the server is told: every playlist of hers, deleted ones too (so
  /// another device learns they are gone). His pushed playlists stay out.
  @visibleForTesting
  String body() {
    final mine = [
      for (final playlist in _playlists.everything)
        if (playlist.kind != PlaylistKind.pushed) playlist.toJson(),
    ];
    return jsonEncode({'playlists': mine});
  }

  /// Sends now if there is anything new and a token. True when the server
  /// has what she has by the end of it.
  Future<bool> reportNow() async {
    if (_sending) {
      _schedule();
      return false;
    }
    final text = body();
    if (text == _lastSent) return true;

    _sending = true;
    try {
      final token = await _tokenStore.readToken();
      if (token == null || token.trim().isEmpty) return false; // poke() later

      final response = await _client
          .post(
            _config.playlistsReportUri,
            headers: {
              'X-Token': token.trim(),
              'Content-Type': 'application/json',
            },
            body: text,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        _lastSent = text;
        return true;
      }
      // A refused token is fixed by saving a new one (poke); anything else
      // may pass, so try again later.
      if (response.statusCode != 401 && response.statusCode != 403) {
        _schedule(_retryAfter);
      }
      return false;
    } catch (error) {
      debugPrint('Playlists not reported: ${error.runtimeType}');
      _schedule(_retryAfter);
      return false;
    } finally {
      _sending = false;
    }
  }
}
