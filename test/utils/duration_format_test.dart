import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/utils/duration_format.dart';

void main() {
  group('formatDuration', () {
    test('zero reads 00:00', () {
      expect(formatDuration(Duration.zero), '00:00');
    });

    test('pads single-digit minutes and seconds', () {
      expect(formatDuration(const Duration(minutes: 1, seconds: 5)), '01:05');
    });

    test('shows the largest value below an hour', () {
      expect(formatDuration(const Duration(minutes: 59, seconds: 59)), '59:59');
    });

    test('ignores fractions of a second', () {
      expect(formatDuration(const Duration(seconds: 7, milliseconds: 900)),
          '00:07');
    });
  });
}
