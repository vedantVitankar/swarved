import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/youtube_result.dart';
import 'secure_token_store.dart';
import 'server_config.dart';

sealed class ServerResult<T> {
  const ServerResult();
}

final class ServerOk<T> extends ServerResult<T> {
  const ServerOk(this.value);
  final T value;
}

final class ServerUnauthorized<T> extends ServerResult<T> {
  const ServerUnauthorized();
}

final class ServerUnavailable<T> extends ServerResult<T> {
  const ServerUnavailable();
}

final class ServerUnexpected<T> extends ServerResult<T> {
  const ServerUnexpected();
}

class ServerApi {
  ServerApi({
    required ServerConfig config,
    required TokenStore tokenStore,
    http.Client? client,
  })  : _config = config,
        _tokenStore = tokenStore,
        _client = client ?? http.Client();

  static const _healthTimeout = Duration(seconds: 5);

  /// The server gives up on a search after 8 seconds. Waiting a little longer
  /// lets its answer arrive, instead of calling a healthy server unreachable.
  static const _searchTimeout = Duration(seconds: 10);

  final ServerConfig _config;
  final TokenStore _tokenStore;
  final http.Client _client;

  Future<ServerResult<void>> healthCheck() {
    return _getJson<void>(
      _config.healthUri,
      timeout: _healthTimeout,
      parse: (body) {
        if (body is! Map<String, dynamic> || body['ok'] != true) {
          throw const FormatException('unexpected health response');
        }
      },
    );
  }

  /// Searches YouTube Music through the server. Nothing is downloaded.
  ///
  /// Completing [abortTrigger] cancels the request. The result is then
  /// [ServerUnavailable], which the caller that aborted it should ignore.
  Future<ServerResult<List<YoutubeResult>>> searchSongs(
    String query, {
    int limit = 10,
    Future<void>? abortTrigger,
  }) {
    return _getJson<List<YoutubeResult>>(
      _config.searchUri(query, limit: limit),
      timeout: _searchTimeout,
      abortTrigger: abortTrigger,
      parse: YoutubeResult.parseList,
    );
  }

  /// One authenticated GET that answers with JSON. Every failure becomes a
  /// [ServerResult], so callers never have to catch anything.
  ///
  /// [parse] turns the decoded body into the value. It throws a
  /// [FormatException] when the body is not what the server promised.
  Future<ServerResult<T>> _getJson<T>(
    Uri uri, {
    required Duration timeout,
    required T Function(Object? body) parse,
    Future<void>? abortTrigger,
  }) async {
    String? token;

    try {
      token = await _tokenStore.readToken();
    } catch (_) {
      return ServerUnexpected<T>();
    }

    if (token == null || token.trim().isEmpty) {
      return ServerUnauthorized<T>();
    }

    try {
      final request = http.AbortableRequest(
        'GET',
        uri,
        abortTrigger: abortTrigger,
      )..headers['X-Token'] = token;

      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);

      if (response.statusCode == 401 || response.statusCode == 403) {
        return ServerUnauthorized<T>();
      }
      if (response.statusCode >= 500) {
        return ServerUnavailable<T>();
      }
      if (response.statusCode != 200) {
        return ServerUnexpected<T>();
      }

      return ServerOk<T>(parse(jsonDecode(response.body)));
    } on TimeoutException {
      return ServerUnavailable<T>();
    } on SocketException {
      return ServerUnavailable<T>();
    } on http.ClientException {
      return ServerUnavailable<T>();
    } on FormatException {
      return ServerUnexpected<T>();
    }
  }

  void close() => _client.close();
}
