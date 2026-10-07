import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:swarved/models/youtube_result.dart';
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
  group('ServerApi.searchSongs', () {
    test('sends the token and the query, and reads the results', () async {
      late http.Request seen;
      final api = _api((request) async {
        seen = request;
        return _json('''
          {"results": [
            {"id": "sJV8kbT1MEU", "title": "Kesariya", "artist": "Arijit Singh",
             "durationSeconds": 268, "thumbnailUrl": "https://example.com/a.jpg"}
          ]}''');
      });

      final result = await api.searchSongs('arijit singh', limit: 7);

      expect(seen.method, 'GET');
      expect(seen.headers['X-Token'], 'secret');
      expect(seen.url.host, 'swarved.duckdns.org');
      expect(seen.url.path, '/api/search');
      expect(seen.url.queryParameters['q'], 'arijit singh');
      expect(seen.url.queryParameters['limit'], '7');

      expect(result, isA<ServerOk<List<YoutubeResult>>>());
      final list = (result as ServerOk<List<YoutubeResult>>).value;
      expect(list.single.id, 'sJV8kbT1MEU');
      expect(list.single.title, 'Kesariya');
    });

    test('sends non-English queries intact and reads non-English titles',
        () async {
      late String sentQuery;
      final api = _api((request) async {
        sentQuery = request.url.queryParameters['q']!;
        return _json('{"results":[{"id":"abc","title":"तुम ही हो"}]}');
      });

      final result = await api.searchSongs('तुम ही हो');

      expect(sentQuery, 'तुम ही हो');
      final list = (result as ServerOk<List<YoutubeResult>>).value;
      expect(list.single.title, 'तुम ही हो');
    });

    test('an empty results list is a success', () async {
      final api = _api((_) async => _json('{"results":[]}'));

      final result = await api.searchSongs('zzzz');

      expect((result as ServerOk<List<YoutubeResult>>).value, isEmpty);
    });

    test('no saved token is unauthorized, and no request is sent', () async {
      final api = _api(
        (_) async => fail('no request expected'),
        token: null,
      );

      expect(
        await api.searchSongs('anything'),
        isA<ServerUnauthorized<List<YoutubeResult>>>(),
      );
    });

    test('401 and 403 are unauthorized', () async {
      for (final status in [401, 403]) {
        final api = _api((_) async => _json('{}', status));

        expect(
          await api.searchSongs('x'),
          isA<ServerUnauthorized<List<YoutubeResult>>>(),
        );
      }
    });

    test('a server error or timeout from the server is unavailable', () async {
      for (final status in [502, 504]) {
        final api = _api((_) async => _json('{}', status));

        expect(
          await api.searchSongs('x'),
          isA<ServerUnavailable<List<YoutubeResult>>>(),
        );
      }
    });

    test('a network failure is unavailable', () async {
      final api = _api((_) async => throw http.ClientException('offline'));

      expect(
        await api.searchSongs('x'),
        isA<ServerUnavailable<List<YoutubeResult>>>(),
      );
    });

    test('an aborted request is unavailable', () async {
      final api = _api((_) async => throw http.RequestAbortedException());

      expect(
        await api.searchSongs('x'),
        isA<ServerUnavailable<List<YoutubeResult>>>(),
      );
    });

    test('a rejected query (400) is unexpected', () async {
      final api = _api((_) async => _json('{"detail":"invalid query"}', 400));

      expect(
        await api.searchSongs('x'),
        isA<ServerUnexpected<List<YoutubeResult>>>(),
      );
    });

    test('a body that is not the promised shape is unexpected', () async {
      for (final body in ['not json', '[]', '{"results":"nope"}']) {
        final api = _api((_) async => _json(body));

        expect(
          await api.searchSongs('x'),
          isA<ServerUnexpected<List<YoutubeResult>>>(),
        );
      }
    });
  });
}
