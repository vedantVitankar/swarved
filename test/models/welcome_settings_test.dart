import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/welcome_settings.dart';

void main() {
  group('WelcomeSettings.parse', () {
    test('reads the line and the signature', () {
      final settings = WelcomeSettings.parse(
        {'line': 'Come as you are.', 'signature': 'Yours, Ved'},
      );

      expect(settings.line, 'Come as you are.');
      expect(settings.signature, 'Yours, Ved');
    });

    test('a bare string is the line', () {
      final settings = WelcomeSettings.parse('  Hello, you.  ');

      expect(settings.line, 'Hello, you.');
      expect(settings.signature, isNull);
    });

    test('blank or wrongly typed parts fall back to the default', () {
      final settings = WelcomeSettings.parse({'line': '   ', 'signature': 7});

      expect(settings.line, isNull);
      expect(settings.signature, isNull);
    });

    test('a missing or wrongly shaped value is all defaults', () {
      for (final json in [null, 42, <Object?>[], true]) {
        final settings = WelcomeSettings.parse(json);
        expect(settings.line, isNull);
        expect(settings.signature, isNull);
      }
    });
  });
}
