import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/services/server_config.dart';
import 'package:swarved/utils/app_profile.dart';

void main() {
  group('app update addresses', () {
    test('hers names only the platform', () {
      final uri = const ServerConfig().appUpdateUri('windows');
      expect(uri.path, '/api/app-update');
      expect(uri.queryParameters, {'platform': 'windows'});
    });

    test('the test profile is named next to the platform', () {
      final uri =
          const ServerConfig(profile: AppProfile.test).appUpdateUri('windows');
      expect(uri.queryParameters, {'profile': 'test', 'platform': 'windows'});
    });

    test('the installer address carries its name and the profile', () {
      expect(
        const ServerConfig().appUpdateFileUri('SwarVed-1.0.1-2.exe').toString(),
        'https://swarved.duckdns.org/api/app-update/file/SwarVed-1.0.1-2.exe',
      );
      final test = const ServerConfig(profile: AppProfile.test)
          .appUpdateFileUri('SwarVed-1.0.1-2.exe');
      expect(test.queryParameters, {'profile': 'test'});
    });
  });
}
