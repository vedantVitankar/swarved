import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:swarved/services/media_cache.dart';
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

const _photo = '0123456789abcdef.jpg';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('swarved_media_ready');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  MediaCache cacheFor(
    Future<http.Response> Function(http.Request request) handler, {
    String? token = 'secret',
  }) {
    return MediaCache(
      config: const ServerConfig(),
      tokenStore: _FakeTokenStore(token),
      client: MockClient(handler),
      directory: () async => directory,
    );
  }

  group('MediaCache readiness', () {
    test(
      'a file is not ready until it is on the phone, and then it is',
      () async {
        final cache = cacheFor(
          (_) async => http.Response.bytes([1, 2, 3], 200),
        );
        var heard = 0;
        cache.addListener(() => heard++);

        expect(cache.isReady(_photo), isFalse);
        // Must finish: a download once waited on itself and never completed.
        await cache.fileFor(_photo).timeout(const Duration(seconds: 5));

        expect(cache.isReady(_photo), isTrue);
        expect(cache.problemFor(_photo), isNull);
        expect(heard, 1);
      },
    );

    test('a refused download is not ready and says why', () async {
      final cache = cacheFor((_) async => http.Response('nope', 404));
      var heard = 0;
      cache.addListener(() => heard++);

      expect(await cache.fileFor(_photo), isNull);

      expect(cache.isReady(_photo), isFalse);
      expect(cache.problemFor(_photo), 'HTTP 404');
      expect(heard, 1);
    });

    test('a missing token says so, and no request is made', () async {
      var requests = 0;
      final cache = cacheFor((_) async {
        requests++;
        return http.Response.bytes([1], 200);
      }, token: null);

      expect(await cache.fileFor(_photo), isNull);

      expect(requests, 0);
      expect(cache.problemFor(_photo), 'no token saved');
    });

    test('a server that sends nothing is a problem, not a file', () async {
      final cache = cacheFor((_) async => http.Response.bytes([], 200));

      expect(await cache.fileFor(_photo), isNull);

      expect(cache.problemFor(_photo), 'the server sent nothing');
      expect(cache.isReady(_photo), isFalse);
    });

    test('a connection that fails says what kind of failure', () async {
      final cache = cacheFor((_) async => throw const SocketException('down'));

      expect(await cache.fileFor(_photo), isNull);

      expect(cache.problemFor(_photo), 'SocketException');
    });

    test('a later success clears the reason', () async {
      var answer = 500;
      final cache = cacheFor(
        (_) async => answer == 200
            ? http.Response.bytes([9], 200)
            : http.Response('no', answer),
      );

      await cache.fileFor(_photo);
      expect(cache.problemFor(_photo), 'HTTP 500');

      answer = 200;
      await cache.fileFor(_photo);

      expect(cache.problemFor(_photo), isNull);
      expect(cache.isReady(_photo), isTrue);
    });

    test(
      'a file already on the phone becomes ready when it is looked up',
      () async {
        final folder = Directory(p.join(directory.path, 'media'))..createSync();
        File(p.join(folder.path, _photo)).writeAsBytesSync([1]);
        final cache = cacheFor((_) async => http.Response('no', 500));

        expect(cache.isReady(_photo), isFalse);
        expect(await cache.existing(_photo), isNotNull);

        expect(cache.isReady(_photo), isTrue);
      },
    );

    test('clearing the downloads makes everything not ready again', () async {
      final cache = cacheFor((_) async => http.Response.bytes([1, 2, 3], 200));
      await cache.fileFor(_photo);

      await cache.clear();

      expect(cache.isReady(_photo), isFalse);
    });
  });
}
