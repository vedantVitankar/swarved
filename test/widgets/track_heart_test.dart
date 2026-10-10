import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:swarved/content/labels.dart';
import 'package:swarved/content/words.dart';
import 'package:swarved/models/playlist.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/services/playlist_service.dart';
import 'package:swarved/services/playlist_store.dart';
import 'package:swarved/theme/swar_glyphs.dart';
import 'package:swarved/widgets/swar_icon.dart';
import 'package:swarved/widgets/track_heart.dart';

class _MemoryStore implements PlaylistStore {
  List<Playlist> kept = [];

  @override
  Future<List<Playlist>> read() async => List.of(kept);

  @override
  Future<void> write(List<Playlist> playlists) async => kept = playlists;
}

Track _song(String id) {
  return Track.youtube(
    videoId: id,
    title: 'Song $id',
    artist: 'Chan',
    duration: const Duration(seconds: 120),
  );
}

Finder _glyph(SwarGlyph glyph) =>
    find.byWidgetPredicate((w) => w is SwarIcon && w.glyph == glyph);

Future<PlaylistService> _show(WidgetTester tester, Track track) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final service = PlaylistService(store: _MemoryStore());
  await service.load();
  await tester.pumpWidget(
    ChangeNotifierProvider<PlaylistService>.value(
      value: service,
      child: MaterialApp(
        home: Scaffold(body: Center(child: TrackHeart(track: track))),
      ),
    ),
  );
  return service;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('TrackHeart', () {
    testWidgets('is an outline until the song is in Liked songs',
        (tester) async {
      final service = await _show(tester, _song('a'));
      expect(_glyph(SwarGlyph.heart), findsOneWidget);

      service.add(Playlist.likedId, _song('a'));
      await tester.pump();

      expect(_glyph(SwarGlyph.heartFilled), findsOneWidget);
      expect(_glyph(SwarGlyph.heart), findsNothing);
    });

    testWidgets('stays an outline when only another song is liked',
        (tester) async {
      final service = await _show(tester, _song('a'));

      service.add(Playlist.likedId, _song('other'));
      await tester.pump();

      expect(_glyph(SwarGlyph.heart), findsOneWidget);
    });

    testWidgets('a tap opens the playlist popup', (tester) async {
      await _show(tester, _song('a'));

      await tester.tap(find.byType(TrackHeart));
      await tester.pumpAndSettle();

      expect(find.text(Labels.addToPlaylist), findsOneWidget);
    });

    testWidgets('holding it likes the song at once, and holding again undoes',
        (tester) async {
      final service = await _show(tester, _song('a'));

      await tester.longPress(find.byType(TrackHeart));
      await tester.pump();

      expect(service.isLiked(_song('a')), isTrue);
      expect(find.text(Words.likedAdded), findsOneWidget);
      expect(find.text(Labels.addToPlaylist), findsNothing);

      await tester.pump(const Duration(seconds: 5));
      await tester.longPress(find.byType(TrackHeart));
      await tester.pump();

      expect(service.isLiked(_song('a')), isFalse);
      expect(find.text(Words.likedRemoved), findsOneWidget);
    });
  });
}
