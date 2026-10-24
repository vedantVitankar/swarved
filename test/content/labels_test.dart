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

  group('Labels.downloadsSummary', () {
    test('says one for one, and counts otherwise', () {
      expect(Labels.downloadsSummary(1, 2 * 1024 * 1024),
          '1 photo or recording, 2.0 MB');
      expect(Labels.downloadsSummary(5, 5 * 1024 * 1024 + 300 * 1024),
          '5 photos and recordings, 5.3 MB');
    });

    test('does not show a size of zero for small files', () {
      expect(Labels.downloadsSummary(1, 1200),
          '1 photo or recording, under 0.1 MB');
    });
  });
}
