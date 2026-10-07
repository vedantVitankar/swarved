import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:swarved/models/youtube_search_status.dart';
import 'package:swarved/services/search_service.dart';
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

const _pause = Duration(milliseconds: 10);

http.Response _found(String id, String title) => http.Response(
      '{"results":[{"id":"$id","title":"$title","artist":"A"}]}',
      200,
      headers: {'content-type': 'application/json'},
    );

SearchService _service(MockClientHandler handler, {String? token = 'secret'}) {
  final api = ServerApi(
    config: const ServerConfig(),
    tokenStore: _FakeTokenStore(token),
    client: MockClient(handler),
  );
  return SearchService(api: api, debounce: _pause);
}

/// Waits until the service is no longer loading.
Future<void> _settle(SearchService service) async {
  for (var i = 0; i < 200; i++) {
    if (service.status != YoutubeSearchStatus.loading) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('the search never finished');
}

Future<void> _wait(Duration d) => Future<void>.delayed(d);

void main() {
  group('SearchService', () {
    test('starts idle', () {
      final service = _service((_) async => fail('no request expected'));

      expect(service.status, YoutubeSearchStatus.idle);
      expect(service.query, '');
      expect(service.results, isEmpty);
      service.dispose();
    });

    test('a blank query stays idle and sends nothing', () async {
      final service = _service((_) async => fail('no request expected'));

      service.onQueryChanged('   ');
      await _wait(_pause * 4);

      expect(service.status, YoutubeSearchStatus.idle);
      service.dispose();
    });

    test('typing quickly sends one search, for the final text', () async {
      final queries = <String>[];
      final service = _service((request) async {
        queries.add(request.url.queryParameters['q']!);
        return _found('abc', 'Song');
      });

      service.onQueryChanged('a');
      service.onQueryChanged('ar');
      service.onQueryChanged('ari');
      expect(service.status, YoutubeSearchStatus.loading);

      await _settle(service);

      expect(queries, ['ari']);
      expect(service.status, YoutubeSearchStatus.loaded);
      expect(service.results.single.title, 'Song');
      service.dispose();
    });

    test('an old answer never replaces a newer one', () async {
      final slow = Completer<http.Response>();
      final service = _service((request) {
        return request.url.queryParameters['q'] == 'first'
            ? slow.future
            : Future.value(_found('two', 'Second'));
      });

      service.onQueryChanged('first');
      await _wait(_pause * 4); // the first request is now in flight
      service.onQueryChanged('second');
      await _settle(service);
      expect(service.results.single.title, 'Second');

      slow.complete(_found('one', 'First'));
      await _wait(_pause * 4);

      expect(service.query, 'second');
      expect(service.results.single.title, 'Second');
      expect(service.status, YoutubeSearchStatus.loaded);
      service.dispose();
    });

    test('earlier results stay while the next search loads', () async {
      final next = Completer<http.Response>();
      final service = _service((request) {
        return request.url.queryParameters['q'] == 'ab'
            ? Future.value(_found('one', 'One'))
            : next.future;
      });

      service.onQueryChanged('ab');
      await _settle(service);
      service.onQueryChanged('abc');
      await _wait(_pause * 4);

      expect(service.status, YoutubeSearchStatus.loading);
      expect(service.results.single.title, 'One');

      next.complete(_found('two', 'Two'));
      await _settle(service);
      expect(service.results.single.title, 'Two');
      service.dispose();
    });

    test('clearing the query goes back to idle and drops the results',
        () async {
      final service = _service((_) async => _found('abc', 'Song'));

      service.onQueryChanged('song');
      await _settle(service);
      expect(service.results, isNotEmpty);

      service.onQueryChanged('');

      expect(service.status, YoutubeSearchStatus.idle);
      expect(service.results, isEmpty);
      service.dispose();
    });

    test('clearing while a search is in flight ignores its answer', () async {
      final slow = Completer<http.Response>();
      final service = _service((_) => slow.future);

      service.onQueryChanged('song');
      await _wait(_pause * 4);
      service.onQueryChanged('');
      slow.complete(_found('abc', 'Song'));
      await _wait(_pause * 4);

      expect(service.status, YoutubeSearchStatus.idle);
      expect(service.results, isEmpty);
      service.dispose();
    });

    test('an unreachable server can be retried', () async {
      var calls = 0;
      final service = _service((_) async {
        calls++;
        return calls == 1 ? http.Response('down', 502) : _found('abc', 'Song');
      });

      service.onQueryChanged('song');
      await _settle(service);
      expect(service.status, YoutubeSearchStatus.unreachable);

      service.searchNow();
      expect(service.status, YoutubeSearchStatus.loading);
      await _settle(service);

      expect(service.status, YoutubeSearchStatus.loaded);
      expect(service.results.single.title, 'Song');
      service.dispose();
    });

    test('no saved token ends as unauthorized', () async {
      final service = _service(
        (_) async => fail('no request expected'),
        token: null,
      );

      service.onQueryChanged('song');
      await _settle(service);

      expect(service.status, YoutubeSearchStatus.unauthorized);
      service.dispose();
    });

    test('a malformed answer ends as unexpected', () async {
      final service = _service((_) async => http.Response('nonsense', 200));

      service.onQueryChanged('song');
      await _settle(service);

      expect(service.status, YoutubeSearchStatus.unexpected);
      expect(service.results, isEmpty);
      service.dispose();
    });

    test('searchNow with nothing typed does nothing', () {
      final service = _service((_) async => fail('no request expected'));

      service.searchNow();

      expect(service.status, YoutubeSearchStatus.idle);
      service.dispose();
    });

    test('disposing mid-search is safe', () async {
      final slow = Completer<http.Response>();
      final service = _service((_) => slow.future);

      service.onQueryChanged('song');
      await _wait(_pause * 4);
      service.dispose();
      slow.complete(_found('abc', 'Song'));
      await _wait(_pause * 4);
      // Reaching here without an error is the pass.
    });
  });
}
