import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/services/server_config.dart';

void main() {
  const config = ServerConfig();

  group('ServerConfig content', () {
    test('the content and the waiting content have their own addresses', () {
      expect(
        config.contentUri.toString(),
        'https://swarved.duckdns.org/api/content',
      );
      expect(
        config.contentWaitUri.toString(),
        'https://swarved.duckdns.org/api/content/wait',
      );
    });

    test('a media file is asked for by name', () {
      expect(
        config.mediaUri('0123456789abcdef.jpg').toString(),
        'https://swarved.duckdns.org/api/media/0123456789abcdef.jpg',
      );
    });

    test('a name is encoded, so it cannot change the path', () {
      final uri = config.mediaUri('../x y');
      expect(uri.path, '/api/media/..%2Fx%20y');
    });
  });
}
