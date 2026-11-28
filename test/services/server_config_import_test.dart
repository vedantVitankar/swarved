import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/services/server_config.dart';

void main() {
  group('ServerConfig.playlistImportUri', () {
    test('points at /api/yt-playlist and sends the link intact', () {
      const link = 'https://www.youtube.com/playlist?list=PLabc_123-xyz&si=q';
      final uri = const ServerConfig().playlistImportUri(link);
      expect(uri.host, 'swarved.duckdns.org');
      expect(uri.path, '/api/yt-playlist');
      expect(uri.queryParameters['url'], link);
    });
  });
}
