import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'media_cache.dart';
import 'secure_token_store.dart';
import 'server_config.dart';

/// Tells the server what has really arrived on this phone: which content it
/// holds and, for each photo and recording that content uses, whether it is
/// on the phone or why it is not. The admin site's Delivery page shows it.
///
/// It reports a few seconds after the last change (a file landing, or a
/// failure), so a burst of downloads is one report. Never throws, and a
/// failure is never shown to her: the next report carries the full state.
class DeliveryReporter {
  DeliveryReporter({
    required ServerConfig config,
    required TokenStore tokenStore,
    required MediaCache mediaCache,
    required String? Function() etag,
    http.Client? client,
    Duration delay = const Duration(seconds: 3),
  }) : _config = config,
       _tokenStore = tokenStore,
       _mediaCache = mediaCache,
       _etag = etag,
       _client = client ?? http.Client(),
       _delay = delay {
    _mediaCache.addListener(_schedule);
  }

  static const _timeout = Duration(seconds: 20);

  /// The server keeps at most this many files in one report.
  static const maxFiles = 400;

  final ServerConfig _config;
  final TokenStore _tokenStore;
  final MediaCache _mediaCache;
  final String? Function() _etag;
  final http.Client _client;
  final Duration _delay;

  Set<String> _names = const {};
  Timer? _timer;

  /// The files the content uses now. Schedules a report.
  void track(Set<String> names) {
    _names = names;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(_delay, () => unawaited(send()));
  }

  /// What the report says: the content the app holds and the state of each
  /// file. Public so it can be tested.
  @visibleForTesting
  Map<String, Object?> body() {
    final files = <String, Map<String, String>>{};
    for (final name in _names.take(maxFiles)) {
      files[name] = _mediaCache.isReady(name)
          ? {'state': 'ready', 'detail': ''}
          : {
              'state': 'failed',
              'detail': _mediaCache.problemFor(name) ?? 'not downloaded yet',
            };
    }
    return {'etag': _etag(), 'files': files};
  }

  /// True when the server took it.
  Future<bool> send() async {
    try {
      final token = await _tokenStore.readToken();
      if (token == null || token.trim().isEmpty) return false;
      final response = await _client
          .post(
            _config.deliveryReportUri,
            headers: {
              'X-Token': token.trim(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body()),
          )
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (error) {
      debugPrint('Delivery not reported: ${error.runtimeType}');
      return false;
    }
  }
}
