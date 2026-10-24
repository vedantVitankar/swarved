import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/utils/app_profile.dart';

void main() {
  group('AppProfile.resolve', () {
    test('a release build is hers', () {
      expect(
          AppProfile.resolve(override: '', release: true), AppProfile.swarnima);
    });

    test('any other build is the test profile', () {
      expect(AppProfile.resolve(override: '', release: false), AppProfile.test);
    });

    test('an override picks a real profile, in any case', () {
      expect(AppProfile.resolve(override: 'Swarnima', release: false),
          AppProfile.swarnima);
      expect(AppProfile.resolve(override: ' TEST ', release: true),
          AppProfile.test);
    });

    test('an unknown override is ignored', () {
      expect(AppProfile.resolve(override: 'admin', release: true),
          AppProfile.swarnima);
      expect(AppProfile.resolve(override: '../her', release: false),
          AppProfile.test);
    });

    test('there are exactly two profiles', () {
      expect(AppProfile.all, [AppProfile.swarnima, AppProfile.test]);
    });
  });
}
