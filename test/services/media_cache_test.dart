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
const _other = 'fedcba9876543210.png';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('swarved_media_cache');
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

  List<String> filesKept() {
    final folder = Directory(p.join(directory.path, 'media'));
    if (!folder.existsSync()) return [];
    return [for (final e in folder.listSync()) p.basename(e.path)]..sort();
  }

  group('MediaCache.fileFor', () {
    test('downloads a file with the token, once, and keeps it', () async {
      var requests = 0;
      late http.Request seen;
      final cache = cacheFor((request) async {
        requests++;
        seen = request;
        return http.Response.bytes([1, 2, 3], 200);
      });

      final first = await cache.fileFor(_photo);
      final second = await cache.fileFor(_photo);

      expect(first?.readAsBytesSync(), [1, 2, 3]);
      expect(second?.path, first?.path);
      expect(requests, 1);
      expect(
        seen.url.toString(),
        'https://swarved.duckdns.org/api/media/$_photo',
      );
      expect(seen.headers['X-Token'], 'secret');
    });

    test('two asks at once share one download', () async {
      var requests = 0;
      final cache = cacheFor((request) async {
        requests++;
        return http.Response.bytes([9], 200);
      });

      final both = await Future.wait([
        cache.fileFor(_photo),
        cache.fileFor(_photo),
      ]);

      expect(requests, 1);
      expect(both[0]?.path, both[1]?.path);
    });

    test('a name that is not the server\'s is refused without asking',
        () async {
      var requests = 0;
      final cache = cacheFor((request) async {
        requests++;
        return http.Response.bytes([1], 200);
      });

      for (final name in [
        '../../etc/passwd',
        'abc.jpg',
        '0123456789abcdef.exe',
        '0123456789abcdef',
        '',
      ]) {
        expect(await cache.fileFor(name), isNull, reason: name);
      }
      expect(requests, 0);
    });

    test('a file the server does not have is null, and nothing is saved',
        () async {
      final cache = cacheFor((request) async => http.Response('', 404));
      expect(await cache.fileFor(_photo), isNull);
      expect(filesKept(), isEmpty);
    });

    test('an empty answer is not kept as a photo', () async {
      final cache = cacheFor((request) async => http.Response.bytes([], 200));
      expect(await cache.fileFor(_photo), isNull);
      expect(filesKept(), isEmpty);
    });

    test('no token means no request and no file', () async {
      var requests = 0;
      final cache = cacheFor(
        (request) async {
          requests++;
          return http.Response.bytes([1], 200);
        },
        token: null,
      );
      expect(await cache.fileFor(_photo), isNull);
      expect(requests, 0);
    });

    test('no connection is null, never an exception', () async {
      final cache = cacheFor(
        (request) async => throw const SocketException('down'),
      );
      expect(await cache.fileFor(_photo), isNull);
    });

    test('a file already on the phone is used without a connection', () async {
      final online = cacheFor((r) async => http.Response.bytes([7, 7], 200));
      await online.fileFor(_photo);

      final offline = cacheFor(
        (request) async => throw const SocketException('down'),
      );
      final file = await offline.fileFor(_photo);

      expect(file?.readAsBytesSync(), [7, 7]);
    });

    test('a failed download can be tried again later', () async {
      var fail = true;
      final cache = cacheFor((request) async {
        return fail
            ? http.Response('', 500)
            : http.Response.bytes([5], 200);
      });

      expect(await cache.fileFor(_photo), isNull);
      fail = false;
      expect((await cache.fileFor(_photo))?.readAsBytesSync(), [5]);
    });
  });

  group('MediaCache.usage and clear', () {
    test('counts the files kept and their size, leaving half-fetched ones out',
        () async {
      final folder = Directory(p.join(directory.path, 'media'))..createSync();
      File(p.join(folder.path, _photo)).writeAsBytesSync([1, 2, 3]);
      File(p.join(folder.path, _other)).writeAsBytesSync([4, 5]);
      File(p.join(folder.path, 'half.part')).writeAsBytesSync([9, 9, 9, 9]);

      final cache = cacheFor((request) async => http.Response('', 500));
      final usage = await cache.usage();

      expect(usage.files, 2);
      expect(usage.bytes, 5);
    });

    test('is empty before anything is fetched', () async {
      final cache = cacheFor((request) async => http.Response('', 500));
      final usage = await cache.usage();

      expect(usage.files, 0);
      expect(usage.bytes, 0);
    });

    test('clear deletes everything, and a photo downloads again after',
        () async {
      var fetches = 0;
      final cache = cacheFor((request) async {
        fetches++;
        return http.Response.bytes([1], 200);
      });
      await cache.fileFor(_photo);
      await cache.fileFor(_other);

      await cache.clear();
      expect(filesKept(), isEmpty);

      await cache.fileFor(_photo);
      expect(fetches, 3);
      expect(filesKept(), [_photo]);
    });
  });

  group('MediaCache.sync', () {
    test('fetches what is missing and removes what is no longer used',
        () async {
      final folder = Directory(p.join(directory.path, 'media'))..createSync();
      File(p.join(folder.path, _other)).writeAsBytesSync([4]);
      File(p.join(folder.path, 'half.part')).writeAsBytesSync([4]);

      final cache = cacheFor((request) async => http.Response.bytes([1], 200));
      await cache.sync({_photo}, tidy: true);

      expect(filesKept(), [_photo]);
    });

    test('without tidy nothing is ever removed', () async {
      final folder = Directory(p.join(directory.path, 'media'))..createSync();
      File(p.join(folder.path, _other)).writeAsBytesSync([4]);

      final cache = cacheFor((request) async => http.Response.bytes([1], 200));
      await cache.sync({_photo});

      expect(filesKept(), unorderedEquals([_photo, _other]));
    });

    test('with nothing in use and tidy, everything is removed', () async {
      final cache = cacheFor((request) async => http.Response.bytes([1], 200));
      await cache.fileFor(_photo);
      await cache.sync({}, tidy: true);
      expect(filesKept(), isEmpty);
    });

    test('a photo that cannot be fetched does not stop the others', () async {
      final cache = cacheFor((request) async {
        return request.url.path.endsWith(_photo)
            ? http.Response('', 500)
            : http.Response.bytes([2], 200);
      });
      await cache.sync({_photo, _other});
      expect(filesKept(), [_other]);
    });
  });
}
