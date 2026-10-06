import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:swarved/services/server_api.dart';
import 'package:swarved/services/server_config.dart';
import 'package:swarved/services/secure_token_store.dart';

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

void main() {
  const config = ServerConfig();

  group('ServerApi.healthCheck', () {
    test('returns ok for a valid authenticated health response', () async {
      final store = _FakeTokenStore('secret');

      final client = MockClient((request) async {
        expect(request.headers['X-Token'], 'secret');
        expect(
          request.url.toString(),
          'https://swarved.duckdns.org/health',
        );

        return http.Response('{"ok":true}', 200);
      });

      final api = ServerApi(
        config: config,
        tokenStore: store,
        client: client,
      );

      expect(await api.healthCheck(), isA<ServerOk<void>>());
    });

    test('returns unauthorized when no token is configured', () async {
      final api = ServerApi(
        config: config,
        tokenStore: _FakeTokenStore(null),
        client: MockClient(
          (_) async => http.Response('{"ok":true}', 200),
        ),
      );

      expect(
        await api.healthCheck(),
        isA<ServerUnauthorized<void>>(),
      );
    });

    test('returns unauthorized for 401 and 403', () async {
      for (final status in [401, 403]) {
        final api = ServerApi(
          config: config,
          tokenStore: _FakeTokenStore('secret'),
          client: MockClient(
            (_) async => http.Response('bad token', status),
          ),
        );

        expect(
          await api.healthCheck(),
          isA<ServerUnauthorized<void>>(),
        );
      }
    });

    test('returns unavailable for a server error', () async {
      final api = ServerApi(
        config: config,
        tokenStore: _FakeTokenStore('secret'),
        client: MockClient(
          (_) async => http.Response('bad gateway', 502),
        ),
      );

      expect(
        await api.healthCheck(),
        isA<ServerUnavailable<void>>(),
      );
    });

    test('returns unavailable for a client/network error', () async {
      final api = ServerApi(
        config: config,
        tokenStore: _FakeTokenStore('secret'),
        client: MockClient((_) async {
          throw http.ClientException('connection failed');
        }),
      );

      expect(
        await api.healthCheck(),
        isA<ServerUnavailable<void>>(),
      );
    });

    test('returns unexpected for a malformed successful response', () async {
      final api = ServerApi(
        config: config,
        tokenStore: _FakeTokenStore('secret'),
        client: MockClient(
          (_) async => http.Response('{"ok":"yes"}', 200),
        ),
      );

      expect(
        await api.healthCheck(),
        isA<ServerUnexpected<void>>(),
      );
    });
  });
}
