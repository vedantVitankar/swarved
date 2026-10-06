import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

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

  static const _timeout = Duration(seconds: 5);

  final ServerConfig _config;
  final TokenStore _tokenStore;
  final http.Client _client;

  Future<ServerResult<void>> healthCheck() async {
    String? token;

    try {
      token = await _tokenStore.readToken();
    } catch (_) {
      return const ServerUnexpected<void>();
    }

    if (token == null || token.trim().isEmpty) {
      return const ServerUnauthorized<void>();
    }

    try {
      final response = await _client.get(_config.healthUri,
          headers: {'X-Token': token}).timeout(_timeout);

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const ServerUnauthorized<void>();
      }
      if (response.statusCode >= 500) {
        return const ServerUnavailable<void>();
      }
      if (response.statusCode != 200) {
        return const ServerUnexpected<void>();
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic> || body['ok'] != true) {
        return const ServerUnexpected<void>();
      }

      return const ServerOk<void>(null);
    } on TimeoutException {
      return const ServerUnavailable<void>();
    } on SocketException {
      return const ServerUnavailable<void>();
    } on http.ClientException {
      return const ServerUnavailable<void>();
    } on FormatException {
      return const ServerUnexpected<void>();
    }
  }

  void close() => _client.close();
}
