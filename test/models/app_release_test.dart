import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/app_release.dart';

Map<String, Object?> valid([Map<String, Object?> change = const {}]) => {
      'version': '1.0.1',
      'build': 2,
      'file': 'SwarVed-1.0.1-2.exe',
      'size': 1234,
      'sha256': 'a' * 64,
      'notes': '  A little nicer.  ',
      ...change,
    };

void main() {
  group('AppRelease.tryParse', () {
    test('reads a whole release', () {
      final release = AppRelease.tryParse(valid())!;
      expect(release.version, '1.0.1');
      expect(release.build, 2);
      expect(release.file, 'SwarVed-1.0.1-2.exe');
      expect(release.size, 1234);
      expect(release.sha256, 'a' * 64);
      expect(release.notes, 'A little nicer.');
    });

    test('notes are optional', () {
      expect(AppRelease.tryParse(valid({'notes': null}))!.notes, '');
      final noNotes = valid()..remove('notes');
      expect(AppRelease.tryParse(noNotes)!.notes, '');
    });

    test('anything that is not a map is not a release', () {
      expect(AppRelease.tryParse(null), isNull);
      expect(AppRelease.tryParse('release'), isNull);
      expect(AppRelease.tryParse([valid()]), isNull);
    });

    test('a missing or wrong field is not a release', () {
      for (final key in ['version', 'build', 'file', 'size', 'sha256']) {
        expect(AppRelease.tryParse(valid()..remove(key)), isNull, reason: key);
      }
      expect(AppRelease.tryParse(valid({'version': '1.0'})), isNull);
      expect(AppRelease.tryParse(valid({'version': 'v1.0.1'})), isNull);
      expect(AppRelease.tryParse(valid({'build': 0})), isNull);
      expect(AppRelease.tryParse(valid({'build': '2'})), isNull);
      expect(AppRelease.tryParse(valid({'size': 0})), isNull);
      expect(AppRelease.tryParse(valid({'size': '12'})), isNull);
      expect(AppRelease.tryParse(valid({'sha256': 'abc'})), isNull);
      expect(AppRelease.tryParse(valid({'sha256': 'A' * 64})), isNull);
    });

    test('only the server\'s own installer names are accepted', () {
      for (final file in [
        '../SwarVed-1.0.1-2.exe',
        'SwarVed-1.0.1-2.apk',
        'SwarVed-1.0.1.exe',
        'evil.exe',
        r'..\SwarVed-1.0.1-2.exe',
        'SwarVed-1.0.1-2.exe/x',
      ]) {
        expect(AppRelease.tryParse(valid({'file': file})), isNull,
            reason: file);
      }
    });
  });
}
