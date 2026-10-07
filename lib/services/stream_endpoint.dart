import 'package:flutter/foundation.dart';
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

/// Turns a YouTube track into the address and headers the audio player needs.
/// The token is read fresh each time and only handed to the player. It is
/// never stored or printed here.
class StreamEndpoint {
  StreamEndpoint({
    required ServerConfig config,
    required TokenStore tokenStore,
  })  : _config = config,
        _tokenStore = tokenStore;

  final ServerConfig _config;
  final TokenStore _tokenStore;

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
}
