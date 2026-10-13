import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/widgets/server_photo.dart';

void main() {
  group('ServerPhoto retry timing', () {
    test('waits 3, 6, 12 and 24 seconds, then every 30', () {
      final seconds = [
        for (var attempt = 0; attempt < 8; attempt++)
          PhotoRetryTiming.delay(attempt).inSeconds,
      ];

      expect(seconds, [3, 6, 12, 24, 30, 30, 30, 30]);
    });
  });
}
