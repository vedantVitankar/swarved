import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:swarved/services/delivery_reporter.dart';
import 'package:swarved/services/media_cache.dart';
import 'package:swarved/services/secure_token_store.dart';
import 'package:swarved/services/server_config.dart';
import 'package:swarved/utils/app_profile.dart';

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

const _here = '0123456789abcdef.jpg';
const _refused = 'fedcba9876543210.mp3';
const _unasked = '1111222233334444.png';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('swarved_delivery');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  /// A cache whose server has [_here] and refuses [_refused].
  MediaCache cache() => MediaCache(
    config: const ServerConfig(),
    tokenStore: _FakeTokenStore('secret'),
    client: MockClient(
      (request) async => request.url.path.endsWith(_here)
          ? http.Response.bytes([1], 200)
          : http.Response('no', 404),
    ),
    directory: () async => directory,
  );

  DeliveryReporter reporterFor(
    MediaCache media, {
    ServerConfig config = const ServerConfig(),
    String? token = 'secret',
    http.Client? client,
    String? etag = '"v3-2026-11-20"',
  }) {
    return DeliveryReporter(
      config: config,
      tokenStore: _FakeTokenStore(token),
      mediaCache: media,
      etag: () => etag,
      client: client ?? MockClient((_) async => http.Response('{}', 200)),
      delay: const Duration(milliseconds: 10),
    );
  }

  group('DeliveryReporter', () {
    test(
      'says ready, why a file failed, and that one was never tried',
      () async {
        final media = cache();
        await media.fileFor(_here);
        await media.fileFor(_refused);
        final reporter = reporterFor(media)..track({_here, _refused, _unasked});

        final body = reporter.body();

        expect(body['etag'], '"v3-2026-11-20"');
        expect(body['files'], {
          _here: {'state': 'ready', 'detail': ''},
          _refused: {'state': 'failed', 'detail': 'HTTP 404'},
          _unasked: {'state': 'failed', 'detail': 'not downloaded yet'},
        });
      },
    );

    test(
      'posts the report with the token, to the profile it belongs to',
      () async {
        final media = cache();
        await media.fileFor(_here);
        late http.Request seen;
        final reporter = reporterFor(
          media,
          config: const ServerConfig(profile: AppProfile.test),
          client: MockClient((request) async {
            seen = request;
            return http.Response('{"ok":true}', 200);
          }),
        )..track({_here});

        expect(await reporter.send(), isTrue);

        expect(seen.method, 'POST');
        expect(seen.url.path, '/api/delivery/report');
        expect(seen.url.queryParameters, {'profile': 'test'});
        expect(seen.headers['X-Token'], 'secret');
        expect(jsonDecode(seen.body)['files'][_here]['state'], 'ready');
      },
    );

    test('hers sends no profile', () async {
      late http.Request seen;
      final reporter = reporterFor(
        cache(),
        client: MockClient((request) async {
          seen = request;
          return http.Response('{}', 200);
        }),
      );

      await reporter.send();

      expect(seen.url.queryParameters, isEmpty);
    });

    test('does nothing without a token', () async {
      var requests = 0;
      final reporter = reporterFor(
        cache(),
        token: null,
        client: MockClient((_) async {
          requests++;
          return http.Response('{}', 200);
        }),
      );

      expect(await reporter.send(), isFalse);
      expect(requests, 0);
    });

    test('a failure is false, never thrown', () async {
      final reporter = reporterFor(
        cache(),
        client: MockClient((_) async => throw const SocketException('down')),
      );

      expect(await reporter.send(), isFalse);
    });

    test('reports on its own a moment after a file lands', () async {
      final media = cache();
      var reports = 0;
      final reporter = reporterFor(
        media,
        client: MockClient((_) async {
          reports++;
          return http.Response('{}', 200);
        }),
      )..track({_here});
      await Future<void>.delayed(const Duration(milliseconds: 60));
      final before = reports;

      await media.fileFor(_here);
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(before, 1);
      expect(reports, 2);
      expect(reporter, isNotNull);
    });
  });
}
