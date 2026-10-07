import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/utils/artwork_url.dart';

void main() {
  group('resizedArtworkUrl', () {
    const small =
        'https://lh3.googleusercontent.com/abc_DEF-123=w120-h120-l90-rj';

    test('asks a Google image host for a bigger picture', () {
      expect(
        resizedArtworkUrl(small, 544),
        'https://lh3.googleusercontent.com/abc_DEF-123=w544-h544-l90-rj',
      );
    });

    test('never makes a picture smaller', () {
      const big = 'https://lh3.googleusercontent.com/abc=w800-h800-l90-rj';

      expect(resizedArtworkUrl(big, 544), big);
    });

    test('leaves other hosts alone', () {
      const other = 'https://i.ytimg.com/vi/abc123/hqdefault.jpg';
      const lookalike = 'https://example.com/pic=w120-h120-l90-rj';

      expect(resizedArtworkUrl(other, 544), other);
      expect(resizedArtworkUrl(lookalike, 544), lookalike);
    });

    test('leaves a Google address without a size alone', () {
      const noSize = 'https://lh3.googleusercontent.com/abc123';

      expect(resizedArtworkUrl(noSize, 544), noSize);
    });

    test('copes with text that is not an address', () {
      expect(resizedArtworkUrl('', 544), '');
      expect(resizedArtworkUrl('not a url', 544), 'not a url');
    });
  });
}
