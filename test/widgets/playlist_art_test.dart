import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/utils/playlist_resolve.dart';
import 'package:swarved/widgets/folder_art.dart';
import 'package:swarved/widgets/playlist_art.dart';
import 'package:swarved/widgets/track_artwork.dart';

List<PlaylistCover> _covers(int n) =>
    [for (var i = 0; i < n; i++) PlaylistCover(url: 'https://x/$i.jpg')];

Future<void> _show(WidgetTester tester, PlaylistArt art) {
  return tester.pumpWidget(
    MaterialApp(home: Scaffold(body: Center(child: art))),
  );
}

void main() {
  group('PlaylistArt', () {
    testWidgets('four pictures make a 2 by 2 grid', (tester) async {
      await _show(
        tester,
        PlaylistArt(seed: 'p', size: 80, covers: _covers(4)),
      );

      final cells = tester.widgetList<TrackArtwork>(find.byType(TrackArtwork));
      expect(cells, hasLength(4));
      expect(cells.every((c) => c.size == 40), isTrue);
      expect(find.byType(FolderArt), findsNothing);
    });

    testWidgets('more than four still shows only four', (tester) async {
      await _show(
        tester,
        PlaylistArt(seed: 'p', size: 80, covers: _covers(6)),
      );

      expect(find.byType(TrackArtwork), findsNWidgets(4));
    });

    testWidgets('one to three pictures show the first alone', (tester) async {
      for (final n in [1, 3]) {
        await _show(
          tester,
          PlaylistArt(seed: 'p', size: 80, covers: _covers(n)),
        );

        final cell = tester.widget<TrackArtwork>(find.byType(TrackArtwork));
        expect(cell.size, 80);
        expect(cell.url, 'https://x/0.jpg');
      }
    });

    testWidgets('no pictures gives the colour block', (tester) async {
      await _show(tester, const PlaylistArt(seed: 'p', size: 80));

      expect(find.byType(FolderArt), findsOneWidget);
      expect(find.byType(TrackArtwork), findsNothing);
    });

    testWidgets('Liked songs keeps its heart whatever the covers',
        (tester) async {
      await _show(
        tester,
        PlaylistArt(seed: 'p', size: 80, isLiked: true, covers: _covers(4)),
      );

      expect(find.byType(TrackArtwork), findsNothing);
      expect(find.byType(FolderArt), findsNothing);
    });
  });
}
