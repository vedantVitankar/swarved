import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'secure_token_store.dart';
import 'server_config.dart';

/// What came back when the app asked the server for his content.
sealed class ContentFetch {
  const ContentFetch();
}

/// Something new: the content as text, and the server's tag for this
/// version, to be sent back next time so the server can say "nothing new".
final class ContentNew extends ContentFetch {
  const ContentNew({required this.body, required this.etag});
  final String body;
  final String etag;
}

/// The app already has the newest content.
final class ContentUnchanged extends ContentFetch {
  const ContentUnchanged();
}

/// He has not published anything yet.
final class ContentNothingPublished extends ContentFetch {
  const ContentNothingPublished();
}

enum ContentFailure {
  /// No token saved, or the server refused it.
  unauthorized,

  /// No connection, a timeout, or the server is busy or down.
  unavailable,

  /// The server answered with something that makes no sense.
  unexpected,

  /// The caller cancelled the request on purpose.
  aborted,
}

final class ContentFailed extends ContentFetch {
  const ContentFailed(this.reason);
  final ContentFailure reason;
}

/// Where the app gets his content from. Tests stand in for it.
abstract interface class ContentSource {
  /// Asks for the content. [etag] is the tag of the copy the app has, if any.
  ///
  /// With [wait] the server holds the request until something new is
  /// published (or for a while), instead of answering at once. Completing
  /// [abortTrigger] cancels the request.
  ///
  /// Never throws: every failure is a [ContentFailed].
  Future<ContentFetch> fetch({
    String? etag,
    bool wait = false,
    Future<void>? abortTrigger,
  });
}

class ServerContentSource implements ContentSource {
  ServerContentSource({
    required ServerConfig config,
    required TokenStore tokenStore,
    http.Client? client,
  })  : _config = config,
        _tokenStore = tokenStore,
        _client = client ?? http.Client();

  static const _timeout = Duration(seconds: 15);

  /// The server holds a waiting request for 25 seconds. Waiting a little
  /// longer lets its answer arrive instead of calling it a failure.
  static const _waitTimeout = Duration(seconds: 40);

  final ServerConfig _config;
  final TokenStore _tokenStore;
  final http.Client _client;

  @override
  Future<ContentFetch> fetch({
    String? etag,
    bool wait = false,
    Future<void>? abortTrigger,
  }) async {
    String? token;
    try {
      token = await _tokenStore.readToken();
    } catch (_) {
      return const ContentFailed(ContentFailure.unexpected);
    }
    if (token == null || token.trim().isEmpty) {
      return const ContentFailed(ContentFailure.unauthorized);
    }

    try {
      final request = http.AbortableRequest(
        'GET',
        wait ? _config.contentWaitUri : _config.contentUri,
        abortTrigger: abortTrigger,
      )..headers['X-Token'] = token;
      if (etag != null && etag.isNotEmpty) {
        request.headers['If-None-Match'] = etag;
      }

      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(wait ? _waitTimeout : _timeout);

      switch (response.statusCode) {
        case 200:
          return ContentNew(
            body: response.body,
            etag: response.headers['etag'] ?? '',
          );
        case 304:
          return const ContentUnchanged();
        case 204:
        case 404:
          return const ContentNothingPublished();
        case 401:
        case 403:
          return const ContentFailed(ContentFailure.unauthorized);
        case 429:
          return const ContentFailed(ContentFailure.unavailable);
        default:
          return ContentFailed(
            response.statusCode >= 500
                ? ContentFailure.unavailable
                : ContentFailure.unexpected,
          );
      }
    } on TimeoutException {
      return const ContentFailed(ContentFailure.unavailable);
    } on http.RequestAbortedException {
      return const ContentFailed(ContentFailure.aborted);
    } on http.ClientException {
      return const ContentFailed(ContentFailure.unavailable);
    } on IOException {
      return const ContentFailed(ContentFailure.unavailable);
    }
  }

  void close() => _client.close();
}
