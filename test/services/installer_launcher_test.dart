import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/services/installer_launcher.dart';

void main() {
  group('windowsInstallerArguments', () {
    test('install quietly, close the app and never restart Windows', () {
      expect(windowsInstallerArguments, contains('/SILENT'));
      expect(windowsInstallerArguments, contains('/CLOSEAPPLICATIONS'));
      expect(windowsInstallerArguments, contains('/SUPPRESSMSGBOXES'));
      expect(windowsInstallerArguments, contains('/NORESTART'));
    });

    test('never show the wizard, which would stop an update half way', () {
      expect(windowsInstallerArguments, isNot(contains('/VERYSILENT')));
      for (final argument in windowsInstallerArguments) {
        expect(argument, startsWith('/'));
      }
    });
  });
}
