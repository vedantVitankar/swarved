import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:swarved/services/content_cache.dart';

void main() {
  late Directory directory;
  late FileContentCache cache;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('swarved_content_cache');
    cache = FileContentCache(directory: () async => directory);
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  File file() => File(p.join(directory.path, FileContentCache.fileName));

  group('FileContentCache', () {
    test('has nothing before anything is saved', () async {
      expect(await cache.read(), isNull);
    });

    test('gives back what was saved, exactly', () async {
      await cache.write(
        const CachedContent(body: '{"notes":[]}', etag: '"v3-2026-10-12"'),
      );

      final back = await cache.read();

      expect(back?.body, '{"notes":[]}');
      expect(back?.etag, '"v3-2026-10-12"');
    });

    test('keeps text with quotes, line breaks and other scripts intact',
        () async {
      const body = '{"note":"She said \\"hi\\"\\nदो शब्द ♥"}';
      await cache.write(const CachedContent(body: body, etag: '"v1"'));
      expect((await cache.read())?.body, body);
    });

    test('a later save replaces the earlier one', () async {
      await cache.write(const CachedContent(body: '{"a":1}', etag: '"v1"'));
      await cache.write(const CachedContent(body: '{"a":2}', etag: '"v2"'));

      final back = await cache.read();

      expect(back?.body, '{"a":2}');
      expect(back?.etag, '"v2"');
    });

    test('leaves no temporary file behind', () async {
      await cache.write(const CachedContent(body: '{}', etag: '"v1"'));
      final names = [
        for (final entry in directory.listSync()) p.basename(entry.path),
      ];
      expect(names, [FileContentCache.fileName]);
    });

    test('a damaged file is as good as none', () async {
      await file().writeAsString('not json');
      expect(await cache.read(), isNull);
    });

    test('a file of the wrong shape is as good as none', () async {
      await file().writeAsString('{"body": 1, "etag": "x"}');
      expect(await cache.read(), isNull);
      await file().writeAsString('[1,2]');
      expect(await cache.read(), isNull);
    });
  });
}
