import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:swarved/models/playback_problem.dart';
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

  group('StreamEndpoint.prepare', () {
    StreamEndpoint endpoint(
      MockClientHandler handler, {
      String? token = 'secret',
      Duration timeout = const Duration(seconds: 5),
    }) {
      return StreamEndpoint(
        config: const ServerConfig(),
        tokenStore: _FakeTokenStore(token),
        client: MockClient(handler),
        probeTimeout: timeout,
      );
    }

    Future<StreamOutcome> prepareWith(
      MockClientHandler handler, {
      String? token = 'secret',
      Duration timeout = const Duration(seconds: 5),
    }) {
      return endpoint(handler, token: token, timeout: timeout)
          .prepare(_youtube('abc'));
    }

    PlaybackProblem? problemOf(StreamOutcome outcome) =>
        outcome is StreamBlocked ? outcome.problem : null;

    test('asks for one byte, with the token, and is ready on 206', () async {
      late http.Request seen;
      final outcome = await prepareWith((request) async {
        seen = request;
        return http.Response('x', 206);
      });

      expect(outcome, isA<StreamReady>());
      expect((outcome as StreamReady).request.headers['X-Token'], 'secret');
      expect(seen.url.path, '/api/play');
      expect(seen.headers['X-Token'], 'secret');
      expect(seen.headers['Range'], 'bytes=0-0');
    });

    test('a plain 200 is ready too', () async {
      final outcome = await prepareWith((_) async => http.Response('x', 200));

      expect(outcome, isA<StreamReady>());
    });

    test('no saved token is blocked without any request', () async {
      final outcome = await prepareWith(
        (_) async => fail('no request expected'),
        token: null,
      );

      expect(problemOf(outcome), PlaybackProblem.noToken);
    });

    test('401 and 403 mean the token was rejected', () async {
      for (final status in [401, 403]) {
        final outcome =
            await prepareWith((_) async => http.Response('', status));

        expect(problemOf(outcome), PlaybackProblem.unauthorized);
      }
    });

    test('404 means the video is gone', () async {
      final outcome = await prepareWith((_) async => http.Response('', 404));

      expect(problemOf(outcome), PlaybackProblem.unavailable);
    });

    test('a server error means YouTube could not be reached just now',
        () async {
      for (final status in [500, 502, 503]) {
        final outcome =
            await prepareWith((_) async => http.Response('', status));

        expect(problemOf(outcome), PlaybackProblem.serverTrouble);
      }
    });

    test('any other answer is unexpected', () async {
      for (final status in [400, 416]) {
        final outcome =
            await prepareWith((_) async => http.Response('', status));

        expect(problemOf(outcome), PlaybackProblem.unexpected);
      }
    });

    test('a network failure means the server is unreachable', () async {
      final clientFailure = await prepareWith(
        (_) async => throw http.ClientException('offline'),
      );
      final socketFailure = await prepareWith(
        (_) async => throw const SocketException('no route'),
      );

      expect(problemOf(clientFailure), PlaybackProblem.unreachable);
      expect(problemOf(socketFailure), PlaybackProblem.unreachable);
    });

    test('an answer that takes too long is a timeout', () async {
      final outcome = await prepareWith(
        (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          return http.Response('x', 206);
        },
        timeout: const Duration(milliseconds: 50),
      );

      expect(problemOf(outcome), PlaybackProblem.timeout);
    });
  });
}
