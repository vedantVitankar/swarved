import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:swarved/services/content_source.dart';
import 'package:swarved/services/secure_token_store.dart';
import 'package:swarved/services/server_config.dart';

class _FakeTokenStore implements TokenStore {
  _FakeTokenStore(this.token);

  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String value) async => token = value;

  @override
  Future<void> deleteToken() async => token = null;
}

ServerContentSource _source(MockClient client, {String? token = 'secret'}) {
  return ServerContentSource(
    config: const ServerConfig(),
    tokenStore: _FakeTokenStore(token),
    client: client,
  );
}

MockClient _answering(int status, {Map<String, String> headers = const {}}) {
  return MockClient(
    (request) async => http.Response('{}', status, headers: headers),
  );
}

void main() {
  group('ServerContentSource.fetch', () {
    test('asks with the token and hands back the content and its tag',
        () async {
      late http.BaseRequest seen;
      final source = _source(MockClient((request) async {
        seen = request;
        return http.Response(
          '{"notes":[]}',
          200,
          headers: {'etag': '"v1-2026-10-12"'},
        );
      }));

      final result = await source.fetch();

      expect(seen.url.toString(), 'https://swarved.duckdns.org/api/content');
      expect(seen.headers['X-Token'], 'secret');
      expect(seen.headers.containsKey('If-None-Match'), isFalse);
      expect(result, isA<ContentNew>());
      final fresh = result as ContentNew;
      expect(fresh.body, '{"notes":[]}');
      expect(fresh.etag, '"v1-2026-10-12"');
    });

    test('sends the tag of the copy it has', () async {
      late http.BaseRequest seen;
      final source = _source(MockClient((request) async {
        seen = request;
        return http.Response('', 304);
      }));

      final result = await source.fetch(etag: '"v1-2026-10-12"');

      expect(seen.headers['If-None-Match'], '"v1-2026-10-12"');
      expect(result, isA<ContentUnchanged>());
    });

    test('waiting uses the waiting address', () async {
      late http.BaseRequest seen;
      final source = _source(MockClient((request) async {
        seen = request;
        return http.Response('', 304);
      }));

      await source.fetch(wait: true, etag: '"v1"');

      expect(
        seen.url.toString(),
        'https://swarved.duckdns.org/api/content/wait',
      );
    });

    test('a missing tag in the answer is an empty tag, not a crash', () async {
      final result = await _source(_answering(200)).fetch();
      expect((result as ContentNew).etag, '');
    });

    test('204 and 404 both mean nothing is published yet', () async {
      expect(
        await _source(_answering(204)).fetch(wait: true),
        isA<ContentNothingPublished>(),
      );
      expect(
        await _source(_answering(404)).fetch(),
        isA<ContentNothingPublished>(),
      );
    });

    test('a refused token is unauthorized', () async {
      for (final status in [401, 403]) {
        final result = await _source(_answering(status)).fetch();
        expect(
          (result as ContentFailed).reason,
          ContentFailure.unauthorized,
          reason: 'status $status',
        );
      }
    });

    test('a busy or broken server is unavailable', () async {
      for (final status in [429, 500, 502, 503]) {
        final result = await _source(_answering(status)).fetch();
        expect(
          (result as ContentFailed).reason,
          ContentFailure.unavailable,
          reason: 'status $status',
        );
      }
    });

    test('an answer that makes no sense is unexpected', () async {
      final result = await _source(_answering(418)).fetch();
      expect((result as ContentFailed).reason, ContentFailure.unexpected);
    });

    test('with no token nothing is asked', () async {
      var asked = false;
      final source = _source(
        MockClient((request) async {
          asked = true;
          return http.Response('{}', 200);
        }),
        token: null,
      );

      final result = await source.fetch();

      expect(asked, isFalse);
      expect((result as ContentFailed).reason, ContentFailure.unauthorized);
    });

    test('a blank token counts as none', () async {
      final result = await _source(_answering(200), token: '   ').fetch();
      expect((result as ContentFailed).reason, ContentFailure.unauthorized);
    });

    test('no connection is unavailable, never an exception', () async {
      final source = _source(
        MockClient((request) async => throw const SocketException('down')),
      );
      final result = await source.fetch();
      expect((result as ContentFailed).reason, ContentFailure.unavailable);
    });

    test('a client error is unavailable, never an exception', () async {
      final source = _source(
        MockClient((request) async => throw http.ClientException('reset')),
      );
      final result = await source.fetch();
      expect((result as ContentFailed).reason, ContentFailure.unavailable);
    });
  });
}
