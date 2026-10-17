import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:swarved/services/content_cache.dart';
import 'package:swarved/utils/app_profile.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('swarved_cache_profile');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  FileContentCache cache(String profile) => FileContentCache(
        directory: () async => directory,
        profile: profile,
      );

  test('each profile keeps its own copy of the content', () async {
    await cache(AppProfile.swarnima).write(
      const CachedContent(body: '{"hers":1}', etag: '"v1"'),
    );

    expect(await cache(AppProfile.test).read(), isNull,
        reason: 'a test build starts with nothing of hers');

    await cache(AppProfile.test).write(
      const CachedContent(body: '{"test":1}', etag: '"v9"'),
    );
    expect((await cache(AppProfile.swarnima).read())!.body, '{"hers":1}');
    expect((await cache(AppProfile.test).read())!.body, '{"test":1}');
  });

  test('hers stays in the file it always used', () async {
    await cache(AppProfile.swarnima).write(
      const CachedContent(body: '{}', etag: '"v1"'),
    );
    expect(
      File(p.join(directory.path, 'content_cache_v1.json')).existsSync(),
      isTrue,
    );
    await cache(AppProfile.test).write(
      const CachedContent(body: '{}', etag: '"v1"'),
    );
    expect(
      File(p.join(directory.path, 'content_cache_test_v1.json')).existsSync(),
      isTrue,
    );
  });
}
