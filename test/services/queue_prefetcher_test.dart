import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/services/queue_prefetcher.dart';
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

const _delay = Duration(milliseconds: 20);
const _settle = Duration(milliseconds: 80);

Future<void> _wait() => Future<void>.delayed(_settle);

void main() {
  late List<http.Request> seen;

  QueuePrefetcher build({
    int status = 200,
    String? token = 'secret',
    MockClientHandler? handler,
  }) {
    seen = [];
    final api = ServerApi(
      config: const ServerConfig(),
      tokenStore: _FakeTokenStore(token),
      client: MockClient(handler ??
          (request) async {
            seen.add(request);
            return http.Response(
              '{"queued":["x"],"mode":"full"}',
              status,
              headers: {'content-type': 'application/json'},
            );
          }),
    );
    return QueuePrefetcher(api: api, delay: _delay);
  }

  test('asks for a full prefetch of the next song, after the delay', () async {
    final prefetcher = build();

    prefetcher.schedule(_youtube('aaaaaaaaaaa'));
    expect(seen, isEmpty);

    await _wait();

    expect(seen, hasLength(1));
    expect(seen.single.method, 'POST');
    expect(seen.single.url.path, '/api/prefetch');
    expect(seen.single.url.queryParameters['ids'], 'aaaaaaaaaaa');
    expect(seen.single.url.queryParameters['mode'], 'full');
    expect(seen.single.headers['X-Token'], 'secret');
  });

  test('a newer song replaces the one waiting', () async {
    final prefetcher = build();

    prefetcher.schedule(_youtube('aaaaaaaaaaa'));
    prefetcher.schedule(_youtube('bbbbbbbbbbb'));
    await _wait();

    expect(seen, hasLength(1));
    expect(seen.single.url.queryParameters['ids'], 'bbbbbbbbbbb');
  });

  test('cancel stops the request', () async {
    final prefetcher = build();

    prefetcher.schedule(_youtube('aaaaaaaaaaa'));
    prefetcher.cancel();
    await _wait();

    expect(seen, isEmpty);
  });

  test('a local song, or nothing, asks for nothing', () async {
    final prefetcher = build();

    prefetcher.schedule(_local());
    prefetcher.schedule(null);
    await _wait();

    expect(seen, isEmpty);
  });

  test('does not ask twice for a song the server accepted', () async {
    final prefetcher = build();

    prefetcher.schedule(_youtube('aaaaaaaaaaa'));
    await _wait();
    prefetcher.schedule(_youtube('aaaaaaaaaaa'));
    await _wait();

    expect(seen, hasLength(1));
  });

  test('asks again after the server failed', () async {
    final prefetcher = build(status: 503);

    prefetcher.schedule(_youtube('aaaaaaaaaaa'));
    await _wait();
    prefetcher.schedule(_youtube('aaaaaaaaaaa'));
    await _wait();

    expect(seen, hasLength(2));
  });

  test('no saved token means no request', () async {
    final prefetcher = build(token: null);

    prefetcher.schedule(_youtube('aaaaaaaaaaa'));
    await _wait();

    expect(seen, isEmpty);
  });

  test('an unexpected failure is swallowed', () async {
    final prefetcher = build(handler: (_) async => throw StateError('boom'));

    prefetcher.schedule(_youtube('aaaaaaaaaaa'));
    await _wait();
    // Reaching here without an unhandled error is the check.
  });

  test('dispose cancels a pending request', () async {
    final prefetcher = build();

    prefetcher.schedule(_youtube('aaaaaaaaaaa'));
    prefetcher.dispose();
    await _wait();

    expect(seen, isEmpty);
  });
}
