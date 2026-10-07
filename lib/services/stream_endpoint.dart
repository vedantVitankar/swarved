import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/playback_problem.dart';
import '../models/track.dart';
import 'secure_token_store.dart';
import 'server_config.dart';

/// Where the player fetches one YouTube song from, and the credentials it
/// has to send along.
class StreamRequest {
  const StreamRequest({required this.uri, required this.headers});

  final Uri uri;
  final Map<String, String> headers;
}

/// The answer to "can this song be streamed right now?".
sealed class StreamOutcome {
  const StreamOutcome();
}

final class StreamReady extends StreamOutcome {
  const StreamReady(this.request);
  final StreamRequest request;
}

final class StreamBlocked extends StreamOutcome {
  const StreamBlocked(this.problem);
  final PlaybackProblem problem;
}

/// Turns a YouTube track into the address and headers the audio player needs,
/// and checks with the server that the song can really be streamed. The token
/// is read fresh each time and only handed to the player. It is never stored
/// or printed here.
class StreamEndpoint {
  StreamEndpoint({
    required ServerConfig config,
    required TokenStore tokenStore,
    http.Client? client,
    Duration probeTimeout = const Duration(seconds: 20),
  })  : _config = config,
        _tokenStore = tokenStore,
        _client = client ?? http.Client(),
        _probeTimeout = probeTimeout;

  final ServerConfig _config;
  final TokenStore _tokenStore;
  final http.Client _client;
  final Duration _probeTimeout;

  /// Null when [track] is not a YouTube song, or no token is saved.
  Future<StreamRequest?> requestFor(Track track) async {
    final videoId = track.videoId;
    if (track.isLocal || videoId == null) return null;

    String? token;
    try {
      token = await _tokenStore.readToken();
    } catch (e) {
      debugPrint('Could not read the saved token: ${e.runtimeType}');
      return null;
    }
    if (token == null || token.trim().isEmpty) return null;

    return StreamRequest(
      uri: _config.playUri(videoId),
      headers: {'X-Token': token.trim()},
    );
  }

  /// Asks the server for the first byte of the song. That is enough to tell
  /// a missing token, a rejected token, a vanished video and an unreachable
  /// server apart, in a way that is the same on every platform. It also lets
  /// the server look the song up, so the real stream starts sooner.
  Future<StreamOutcome> prepare(Track track) async {
    final request = await requestFor(track);
    if (request == null) return const StreamBlocked(PlaybackProblem.noToken);

    try {
      final response = await _client.get(request.uri, headers: {
        ...request.headers,
        'Range': 'bytes=0-0'
      }).timeout(_probeTimeout);

      return switch (response.statusCode) {
        200 || 206 => StreamReady(request),
        401 || 403 => const StreamBlocked(PlaybackProblem.unauthorized),
        404 => const StreamBlocked(PlaybackProblem.unavailable),
        >= 500 => const StreamBlocked(PlaybackProblem.serverTrouble),
        _ => const StreamBlocked(PlaybackProblem.unexpected),
      };
    } on TimeoutException {
      return const StreamBlocked(PlaybackProblem.timeout);
    } on SocketException {
      return const StreamBlocked(PlaybackProblem.unreachable);
    } on http.ClientException {
      return const StreamBlocked(PlaybackProblem.unreachable);
    }
  }
}
