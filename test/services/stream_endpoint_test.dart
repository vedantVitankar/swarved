import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/services/secure_token_store.dart';
import 'package:swarved/services/server_config.dart';
import 'package:swarved/services/stream_endpoint.dart';

class _FakeTokenStore implements TokenStore {
  _FakeTokenStore(this.token, {this.throws = false});

  String? token;
  final bool throws;

  @override
  Future<String?> readToken() async {
    if (throws) throw StateError('storage failed');
    return token;
  }

  @override
  Future<void> writeToken(String value) async => token = value;

  @override
  Future<void> deleteToken() async => token = null;
}

Track _youtube(String id) => Track.youtube(
      videoId: id,
      title: 'Song',
      artist: 'Singer',
      duration: const Duration(minutes: 3),
    );

Track _local() => Track(
      filePath: '/music/a.mp3',
      title: 'A',
      artist: 'Artist',
      album: 'Album',
      duration: const Duration(minutes: 3),
      folder: 'music',
    );

Future<StreamRequest?> _request(_FakeTokenStore store, Track track) {
  return StreamEndpoint(config: const ServerConfig(), tokenStore: store)
      .requestFor(track);
}

void main() {
  group('StreamEndpoint.requestFor', () {
    test('a YouTube track gets the play address and the token header',
        () async {
      final request =
          await _request(_FakeTokenStore('secret'), _youtube('sJV8kbT1MEU'));

      expect(request, isNotNull);
      expect(request!.uri.host, 'swarved.duckdns.org');
      expect(request.uri.path, '/api/play');
      expect(request.uri.queryParameters['id'], 'sJV8kbT1MEU');
      expect(request.headers, {'X-Token': 'secret'});
    });

    test('ids with dashes and underscores stay intact', () async {
      final request =
          await _request(_FakeTokenStore('secret'), _youtube('nbwLp_9Pn-c'));

      expect(request!.uri.queryParameters['id'], 'nbwLp_9Pn-c');
    });

    test('the saved token is trimmed', () async {
      final request =
          await _request(_FakeTokenStore('  secret \n'), _youtube('abc'));

      expect(request!.headers['X-Token'], 'secret');
    });

    test('a local track has nothing to stream', () async {
      final request = await _request(_FakeTokenStore('secret'), _local());

      expect(request, isNull);
    });

    test('no saved token means no request', () async {
      expect(await _request(_FakeTokenStore(null), _youtube('abc')), isNull);
      expect(await _request(_FakeTokenStore('  '), _youtube('abc')), isNull);
    });

    test('a storage failure means no request, and no crash', () async {
      final store = _FakeTokenStore('secret', throws: true);

      expect(await _request(store, _youtube('abc')), isNull);
    });
  });

  group('ServerConfig.playUri', () {
    test('points at /api/play with the video id', () {
      final uri = const ServerConfig().playUri('abc123');

      expect(uri.toString(), 'https://swarved.duckdns.org/api/play?id=abc123');
    });
  });
}
