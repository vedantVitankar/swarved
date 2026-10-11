import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swarved/content/words.dart';
import 'package:swarved/models/playlist.dart';
import 'package:swarved/models/playlist_item.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/models/youtube_result.dart';
import 'package:swarved/services/playlist_service.dart';
import 'package:swarved/services/playlist_store.dart';
import 'package:swarved/services/save_controller.dart';
import 'package:swarved/services/saved_songs_index.dart';
import 'package:swarved/services/song_saver.dart';
import 'package:swarved/theme/swar_glyphs.dart';
import 'package:swarved/widgets/playlist_item_row.dart';
import 'package:swarved/widgets/swar_icon.dart';
import 'package:swarved/widgets/track_tile.dart';

class _MemoryStore implements PlaylistStore {
  List<Playlist> kept = [];

  @override
  Future<List<Playlist>> read() async => List.of(kept);

  @override
  Future<void> write(List<Playlist> playlists) async => kept = playlists;
}

Track _youtube(String id) => Track.youtube(
      videoId: id,
      title: 'Song $id',
      artist: 'Chan',
      duration: const Duration(seconds: 125),
    );

Track _local() => Track(
      filePath: '/music/a.mp3',
      title: 'Local song',
      artist: 'Singer',
      album: '',
      duration: const Duration(seconds: 200),
      folder: 'music',
    );

Finder _glyph(SwarGlyph glyph) =>
    find.byWidgetPredicate((w) => w is SwarIcon && w.glyph == glyph);

class _Setup {
  late final PlaylistService playlists;
  late final SavedSongsIndex index;
  late final SaveController saves;
  final saved = <String>[];
}

Future<_Setup> _show(WidgetTester tester, Widget row) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final setup = _Setup();
  setup.playlists = PlaylistService(store: _MemoryStore());
  await setup.playlists.load();
  setup.index = SavedSongsIndex(fileExists: (_) => true);
  setup.saves = SaveController(
    save: (
      YoutubeResult song, {
      required String folderPath,
      void Function(int received, int? total)? onProgress,
    }) async {
      setup.saved.add(song.id);
      final path = '$folderPath/${song.id}.mp3';
      await setup.index.record(song.id, path);
      return SaveDone(path);
    },
    index: setup.index,
    folderPath: () => '/music',
    onSaved: (_) async {},
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PlaylistService>.value(value: setup.playlists),
        ChangeNotifierProvider<SaveController>.value(value: setup.saves),
      ],
      child: MaterialApp(home: Scaffold(body: row)),
    ),
  );
  return setup;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('TrackTile', () {
    testWidgets('a local song shows its length and a heart, and no download',
        (tester) async {
      await _show(tester, TrackTile(track: _local(), onTap: () {}));

      expect(find.text('03:20'), findsOneWidget);
      expect(_glyph(SwarGlyph.heart), findsOneWidget);
      expect(_glyph(SwarGlyph.download), findsNothing);
    });

    testWidgets('a YouTube song also shows a download', (tester) async {
      await _show(tester, TrackTile(track: _youtube('a'), onTap: () {}));

      expect(find.text('02:05'), findsOneWidget);
      expect(_glyph(SwarGlyph.download), findsOneWidget);
      expect(_glyph(SwarGlyph.heart), findsOneWidget);
    });

    testWidgets('holding the row likes the song, and again takes it out',
        (tester) async {
      final setup = await _show(
        tester,
        TrackTile(track: _youtube('a'), onTap: () {}),
      );

      await tester.longPress(find.text('Song a'));
      await tester.pump();

      expect(setup.playlists.isLiked(_youtube('a')), isTrue);
      expect(_glyph(SwarGlyph.heartFilled), findsOneWidget);
      expect(find.text(Words.likedAdded), findsOneWidget);

      ScaffoldMessenger.of(tester.element(find.byType(TrackTile)))
          .removeCurrentSnackBar();
      await tester.pump();
      await tester.longPress(find.text('Song a'));
      await tester.pump();

      expect(setup.playlists.isLiked(_youtube('a')), isFalse);
      expect(find.text(Words.likedRemoved), findsOneWidget);
    });

    testWidgets('tapping the row plays it, and does not like it',
        (tester) async {
      var taps = 0;
      final setup = await _show(
        tester,
        TrackTile(track: _youtube('a'), onTap: () => taps++),
      );

      await tester.tap(find.text('Song a'));
      await tester.pump();

      expect(taps, 1);
      expect(setup.playlists.isLiked(_youtube('a')), isFalse);
    });

    testWidgets('the download saves the song without playing it',
        (tester) async {
      var taps = 0;
      final setup = await _show(
        tester,
        TrackTile(track: _youtube('a'), onTap: () => taps++),
      );

      await tester.tap(_glyph(SwarGlyph.download));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(setup.saved, ['a']);
      expect(taps, 0);
      expect(_glyph(SwarGlyph.saved), findsOneWidget);
    });
  });

  group('PlaylistItemRow', () {
    PlaylistItem item(Track track) =>
        PlaylistItem.fromTrack(track, addedAt: DateTime.utc(2026, 10, 11));

    testWidgets('a YouTube line has download, length and heart',
        (tester) async {
      final track = _youtube('a');
      await _show(
        tester,
        PlaylistItemRow(item: item(track), track: track, onTap: () {}),
      );

      expect(_glyph(SwarGlyph.download), findsOneWidget);
      expect(find.text('02:05'), findsOneWidget);
      expect(_glyph(SwarGlyph.heart), findsOneWidget);
    });

    testWidgets('a local line has length and heart but no download',
        (tester) async {
      final track = _local();
      await _show(
        tester,
        PlaylistItemRow(item: item(track), track: track, onTap: () {}),
      );

      expect(_glyph(SwarGlyph.download), findsNothing);
      expect(find.text('03:20'), findsOneWidget);
      expect(_glyph(SwarGlyph.heart), findsOneWidget);
    });

    testWidgets('a local line missing from this device has no heart',
        (tester) async {
      final gone = item(_local());
      await _show(
        tester,
        PlaylistItemRow(item: gone, track: null, onTap: () {}),
      );

      expect(_glyph(SwarGlyph.heart), findsNothing);
      expect(_glyph(SwarGlyph.download), findsNothing);
      expect(find.text('03:20'), findsOneWidget);
    });

    testWidgets('holding the row does not like it: that moves it',
        (tester) async {
      final track = _youtube('a');
      final setup = await _show(
        tester,
        PlaylistItemRow(item: item(track), track: track, onTap: () {}),
      );

      await tester.longPress(find.text('Song a'));
      await tester.pump();

      expect(setup.playlists.isLiked(track), isFalse);
    });

    testWidgets('holding the heart likes the song', (tester) async {
      final track = _youtube('a');
      final setup = await _show(
        tester,
        PlaylistItemRow(item: item(track), track: track, onTap: () {}),
      );

      await tester.longPress(_glyph(SwarGlyph.heart));
      await tester.pump();

      expect(setup.playlists.isLiked(track), isTrue);
    });
  });
}
