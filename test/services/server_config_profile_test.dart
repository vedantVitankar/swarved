import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/services/server_config.dart';
import 'package:swarved/utils/app_profile.dart';

void main() {
  const hers = ServerConfig();
  const trial = ServerConfig(profile: AppProfile.test);

  group('ServerConfig profile', () {
    test('hers sends no profile, so older copies of the app are unchanged',
        () {
      expect(hers.contentUri.queryParameters, isEmpty);
      expect(hers.contentWaitUri.queryParameters, isEmpty);
      expect(hers.playlistsReportUri.queryParameters, isEmpty);
      expect(hers.mediaUri('a.jpg').queryParameters, isEmpty);
      expect(hers.playlistsUri.queryParameters, isEmpty);
    });

    test('the test profile names itself on content and playlists', () {
      for (final uri in [
        trial.contentUri,
        trial.contentWaitUri,
        trial.playlistsReportUri,
        trial.mediaUri('a.jpg'),
        trial.playlistsUri,
      ]) {
        expect(uri.queryParameters, {'profile': 'test'});
      }
      expect(trial.contentUri.path, '/api/content');
      expect(trial.contentWaitUri.path, '/api/content/wait');
      expect(trial.playlistsReportUri.path, '/api/playlists/report');
      expect(trial.mediaUri('a b.jpg').path, '/api/media/a%20b.jpg');
      expect(trial.playlistsUri.path, '/api/playlists');
    });

    test('songs, search and the rest do not depend on the profile', () {
      expect(trial.playUri('abc').toString(), hers.playUri('abc').toString());
      expect(trial.searchUri('x').toString(), hers.searchUri('x').toString());
    });
  });
}
