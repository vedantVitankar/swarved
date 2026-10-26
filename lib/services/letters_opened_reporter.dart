import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'secure_token_store.dart';
import 'server_config.dart';

/// Tells the server which letters she has opened and when, so the admin site
/// can mark each one Opened or Not opened. Never throws, and a failure is
/// never shown to her: the next report carries everything again.
class LettersOpenedReporter {
  LettersOpenedReporter({
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
  Future<bool> report(Map<String, DateTime> opened) async {
    try {
      final token = await _tokenStore.readToken();
      if (token == null || token.trim().isEmpty) return false;
      final response = await _client
          .post(
            _config.lettersOpenedUri,
            headers: {
              'X-Token': token.trim(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'opened': {
                for (final entry in opened.entries)
                  entry.key: entry.value.toUtc().toIso8601String(),
              },
            }),
          )
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (error) {
      debugPrint('Letters not reported: ${error.runtimeType}');
      return false;
    }
  }
}
