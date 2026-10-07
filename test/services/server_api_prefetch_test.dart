import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:swarved/models/prefetch_mode.dart';
import 'package:swarved/services/secure_token_store.dart';
import 'package:swarved/services/server_api.dart';
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

http.Response _json(String body, [int status = 200]) => http.Response(
      body,
      status,
      headers: {'content-type': 'application/json'},
    );

ServerApi _api(MockClientHandler handler, {String? token = 'secret'}) {
  return ServerApi(
    config: const ServerConfig(),
    tokenStore: _FakeTokenStore(token),
    client: MockClient(handler),
  );
}

void main() {
  group('ServerConfig.prefetchUri', () {
    test('points at /api/prefetch with the ids and the mode', () {
      final uri = const ServerConfig()
          .prefetchUri(['aaaaaaaaaaa', 'bbbbbbbbbbb'], PrefetchMode.full);

      expect(uri.path, '/api/prefetch');
      expect(uri.queryParameters['ids'], 'aaaaaaaaaaa,bbbbbbbbbbb');
      expect(uri.queryParameters['mode'], 'full');
    });
  });

  group('ServerApi.prefetch', () {
    test('posts the ids and mode with the token, and returns what was queued',
        () async {
      late http.Request seen;
      final api = _api((request) async {
        seen = request;
        return _json('{"queued": ["aaaaaaaaaaa"], "mode": "resolve"}');
      });

      final result = await api.prefetch(
        ['aaaaaaaaaaa', 'bbbbbbbbbbb'],
        mode: PrefetchMode.resolve,
      );

      expect(seen.method, 'POST');
      expect(seen.url.path, '/api/prefetch');
      expect(seen.headers['X-Token'], 'secret');
      expect(seen.url.queryParameters['ids'], 'aaaaaaaaaaa,bbbbbbbbbbb');
      expect(seen.url.queryParameters['mode'], 'resolve');

      expect(result, isA<ServerOk<List<String>>>());
      expect((result as ServerOk<List<String>>).value, ['aaaaaaaaaaa']);
    });

    test('mode full is sent as full', () async {
      late http.Request seen;
      final api = _api((request) async {
        seen = request;
        return _json('{"queued": [], "mode": "full"}');
      });

      await api.prefetch(['aaaaaaaaaaa'], mode: PrefetchMode.full);

      expect(seen.url.queryParameters['mode'], 'full');
    });

    test('repeated ids are sent once, and no more than five', () async {
      late http.Request seen;
      final api = _api((request) async {
        seen = request;
        return _json('{"queued": []}');
      });

      await api.prefetch(
        ['a0', 'a1', 'a1', 'a2', 'a3', 'a4', 'a5', 'a6'],
        mode: PrefetchMode.resolve,
      );

      expect(seen.url.queryParameters['ids'], 'a0,a1,a2,a3,a4');
    });

    test('nothing to ask for means no request at all', () async {
      final api = _api((_) async => fail('no request expected'));

      final result = await api.prefetch([], mode: PrefetchMode.resolve);

      expect((result as ServerOk<List<String>>).value, isEmpty);
    });

    test('no saved token means unauthorized, without a request', () async {
      final api = _api((_) async => fail('no request expected'), token: null);

      final result =
          await api.prefetch(['aaaaaaaaaaa'], mode: PrefetchMode.resolve);

      expect(result, isA<ServerUnauthorized<List<String>>>());
    });

    test('401 and 403 mean the token was rejected', () async {
      for (final status in [401, 403]) {
        final api = _api((_) async => _json('{}', status));

        final result =
            await api.prefetch(['aaaaaaaaaaa'], mode: PrefetchMode.resolve);

        expect(result, isA<ServerUnauthorized<List<String>>>());
      }
    });

    test('a server error means unavailable', () async {
      final api = _api((_) async => _json('{}', 503));

      final result =
          await api.prefetch(['aaaaaaaaaaa'], mode: PrefetchMode.resolve);

      expect(result, isA<ServerUnavailable<List<String>>>());
    });

    test('a network failure means unavailable', () async {
      final api = _api((_) async => throw const SocketException('no route'));

      final result =
          await api.prefetch(['aaaaaaaaaaa'], mode: PrefetchMode.resolve);

      expect(result, isA<ServerUnavailable<List<String>>>());
    });

    test('a 400 or an answer in the wrong shape is unexpected', () async {
      final rejected = await _api((_) async => _json('{}', 400))
          .prefetch(['aaaaaaaaaaa'], mode: PrefetchMode.resolve);
      final wrongShape = await _api((_) async => _json('{"nope": 1}'))
          .prefetch(['aaaaaaaaaaa'], mode: PrefetchMode.resolve);

      expect(rejected, isA<ServerUnexpected<List<String>>>());
      expect(wrongShape, isA<ServerUnexpected<List<String>>>());
    });
  });
}
