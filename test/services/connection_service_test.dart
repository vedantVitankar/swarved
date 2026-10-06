import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:swarved/models/connection_status.dart';
import 'package:swarved/services/connection_service.dart';
import 'package:swarved/services/secure_token_store.dart';
import 'package:swarved/services/server_api.dart';
import 'package:swarved/services/server_config.dart';

class _FakeTokenStore implements TokenStore {
  _FakeTokenStore({this.token, this.failWrites = false});

  String? token;
  final bool failWrites;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String value) async {
    if (failWrites) throw Exception('storage failed');
    token = value;
  }

  @override
  Future<void> deleteToken() async => token = null;
}

ConnectionService _service(_FakeTokenStore store, http.Client client) {
  return ConnectionService(
    api: ServerApi(
      config: const ServerConfig(),
      tokenStore: store,
      client: client,
    ),
    tokenStore: store,
  );
}

void main() {
  group('ConnectionService', () {
    test('load reports whether a token is saved', () async {
      final service = _service(
        _FakeTokenStore(token: 'abc'),
        MockClient((_) async => http.Response('{"ok":true}', 200)),
      );

      await service.load();

      expect(service.hasToken, true);
      expect(service.status, ConnectionStatus.unknown);
    });

    test('a blank token is neither saved nor tested', () async {
      final store = _FakeTokenStore();
      final service = _service(
        store,
        MockClient((_) async => fail('no request expected')),
      );

      expect(await service.saveAndTest('   '), false);
      expect(store.token, isNull);
      expect(service.status, ConnectionStatus.unknown);
    });

    test('a valid token is saved and connects', () async {
      final store = _FakeTokenStore();
      final service = _service(
        store,
        MockClient((_) async => http.Response('{"ok":true}', 200)),
      );
      final seen = <ConnectionStatus>[];
      service.addListener(() => seen.add(service.status));

      expect(await service.saveAndTest(' secret '), true);

      expect(store.token, 'secret');
      expect(service.hasToken, true);
      expect(seen, [ConnectionStatus.checking, ConnectionStatus.connected]);
    });

    test('a rejected token keeps the token but reports badToken', () async {
      final service = _service(
        _FakeTokenStore(),
        MockClient((_) async => http.Response('nope', 401)),
      );

      await service.saveAndTest('wrong');

      expect(service.status, ConnectionStatus.badToken);
      expect(service.hasToken, true);
    });

    test('an unreachable server reports unreachable', () async {
      final service = _service(
        _FakeTokenStore(),
        MockClient((_) async {
          throw http.ClientException('connection failed');
        }),
      );

      await service.saveAndTest('secret');

      expect(service.status, ConnectionStatus.unreachable);
    });

    test('a storage failure saves nothing and reports unexpected', () async {
      final service = _service(
        _FakeTokenStore(failWrites: true),
        MockClient((_) async => fail('no request expected')),
      );

      expect(await service.saveAndTest('secret'), false);
      expect(service.hasToken, false);
      expect(service.status, ConnectionStatus.unexpected);
    });

    test('forget removes the token and resets the status', () async {
      final store = _FakeTokenStore();
      final service = _service(
        store,
        MockClient((_) async => http.Response('{"ok":true}', 200)),
      );
      await service.saveAndTest('secret');

      await service.forget();

      expect(store.token, isNull);
      expect(service.hasToken, false);
      expect(service.status, ConnectionStatus.unknown);
    });
  });
}
