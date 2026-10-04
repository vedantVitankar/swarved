import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/content/labels.dart';

void main() {
  group('Labels.songCount', () {
    test('uses the singular for exactly one song', () {
      expect(Labels.songCount(1), '1 song');
    });

    test('uses the plural for everything else', () {
      expect(Labels.songCount(0), '0 songs');
      expect(Labels.songCount(24), '24 songs');
    });
  });
}
