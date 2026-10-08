import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/services/server_config.dart';

void main() {
  group('ServerConfig.exportUri', () {
    test('points at /api/export with the song details', () {
      final uri = const ServerConfig().exportUri(
        'sJV8kbT1MEU',
        title: 'Kesariya',
        artist: 'Arijit Singh',
        cover: 'https://lh3.googleusercontent.com/a=w120-h120-l90-rj',
      );

      expect(uri.host, 'swarved.duckdns.org');
      expect(uri.path, '/api/export');
      expect(uri.queryParameters, {
        'id': 'sJV8kbT1MEU',
        'title': 'Kesariya',
        'artist': 'Arijit Singh',
        'cover': 'https://lh3.googleusercontent.com/a=w120-h120-l90-rj',
      });
    });

    test('leaves out blank or missing details', () {
      final uri = const ServerConfig()
          .exportUri('abc', title: 'Song', artist: '', cover: null);

      expect(uri.queryParameters, {'id': 'abc', 'title': 'Song'});
    });

    test('titles with spaces and symbols survive the trip', () {
      final uri = const ServerConfig()
          .exportUri('abc', title: 'A & B = C?', artist: 'Zoë');

      expect(uri.queryParameters['title'], 'A & B = C?');
      expect(uri.queryParameters['artist'], 'Zoë');
    });
  });
}
