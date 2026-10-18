import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'secure_token_store.dart';
import 'server_config.dart';

/// Tells the server which of his recordings have played on this phone, so
/// the admin site can mark each one "Played" or "Waiting". Never throws, and
/// a failure is never shown to her: the next report carries the full state
/// again.
class VoiceProgressReporter {
  VoiceProgressReporter({
    required ServerConfig config,
    required TokenStore tokenStore,
    http.Client? client,
  })  : _config = config,
        _tokenStore = tokenStore,
        _client = client ?? http.Client();

  static const _timeout = Duration(seconds: 20);

  final ServerConfig _config;
  final TokenStore _tokenStore;
  final http.Client _client;

  /// True when the server took it.
  Future<bool> report(String? last, List<String> played) async {
    try {
      final token = await _tokenStore.readToken();
      if (token == null || token.trim().isEmpty) return false;
      final response = await _client
          .post(
            _config.voicesPlayedUri,
            headers: {
              'X-Token': token.trim(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'last': last, 'played': played}),
          )
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (error) {
      debugPrint('Voice progress not reported: ${error.runtimeType}');
      return false;
    }
  }
}
