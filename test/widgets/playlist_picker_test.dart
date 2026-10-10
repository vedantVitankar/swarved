import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swarved/content/labels.dart';
import 'package:swarved/content/words.dart';
import 'package:swarved/models/playlist.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/services/playlist_service.dart';
import 'package:swarved/services/playlist_store.dart';
import 'package:swarved/theme/swar_glyphs.dart';
import 'package:swarved/widgets/playlist_picker.dart';
import 'package:swarved/widgets/swar_icon.dart';

class _MemoryStore implements PlaylistStore {
  _MemoryStore([List<Playlist> initial = const []]) : kept = List.of(initial);

  List<Playlist> kept;

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

Future<PlaylistService> _service([List<Playlist> initial = const []]) async {
  final service = PlaylistService(store: _MemoryStore(initial));
  await service.load();
  return service;
}

void _screen(WidgetTester tester, {double width = 800, double height = 1400}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _open(
  WidgetTester tester,
  Track track,
  PlaylistService service,
) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showPlaylistPicker(context, track, service),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Finder get _ticks => find.byWidgetPredicate(
      (w) => w is SwarIcon && w.glyph == SwarGlyph.check,
    );

List<String> _keys(PlaylistService service, String id) =>
    [for (final item in service.byId(id)!.items) item.key];

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('the playlist popup', () {
    testWidgets('lists Liked songs first, then her playlists, with counts',
        (tester) async {
      _screen(tester);
      final service = await _service();
      final road = service.create('Road trip')!;
      service.add(road.id, _song('a'));
      service.add(road.id, _song('b'));

      await _open(tester, _song('z'), service);

      expect(find.text(Labels.addToPlaylist), findsOneWidget);
      expect(find.text('Liked songs'), findsOneWidget);
      expect(find.text('Road trip'), findsOneWidget);
      expect(find.text('2 songs'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Liked songs')).dy,
        lessThan(tester.getTopLeft(find.text('Road trip')).dy),
      );
    });

    testWidgets('shows which song it is about', (tester) async {
      _screen(tester);
      final service = await _service();

      await _open(tester, _song('z'), service);

      expect(find.text('Song z'), findsOneWidget);
    });

    testWidgets('ticks the playlists the song is already in', (tester) async {
      _screen(tester);
      final service = await _service();
      final road = service.create('Road trip')!;
      service.create('Rain');
      service.add(road.id, _song('a'));

      await _open(tester, _song('a'), service);

      expect(_ticks, findsOneWidget);
    });

    testWidgets('does not list a playlist he sent', (tester) async {
      _screen(tester);
      final service = await _service([
        Playlist(
          id: 'sent',
          name: 'For you',
          kind: PlaylistKind.pushed,
          items: const [],
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      ]);

      await _open(tester, _song('a'), service);

      expect(find.text('For you'), findsNothing);
    });

    testWidgets('a tap changes the tick but saves nothing yet',
        (tester) async {
      _screen(tester);
      final service = await _service();
      final road = service.create('Road trip')!;
      service.add(road.id, _song('a'));
      await _open(tester, _song('a'), service);
      expect(_ticks, findsOneWidget);

      await tester.tap(find.text('Road trip'));
      await tester.pump();

      expect(_ticks, findsNothing);
      expect(_keys(service, road.id), ['yt:a']);
    });

    testWidgets('Done applies the ticks and says so', (tester) async {
      _screen(tester);
      final service = await _service();
      final road = service.create('Road trip')!;
      service.add(road.id, _song('a'));
      await _open(tester, _song('a'), service);

      await tester.tap(find.text('Liked songs'));
      await tester.tap(find.text('Road trip'));
      await tester.tap(find.text(Labels.done));
      await tester.pumpAndSettle();

      expect(service.isLiked(_song('a')), isTrue);
      expect(_keys(service, road.id), isEmpty);
      expect(find.text(Words.playlistsSaved), findsOneWidget);
      expect(find.text(Labels.addToPlaylist), findsNothing);
    });

    testWidgets('Cancel leaves everything as it was', (tester) async {
      _screen(tester);
      final service = await _service();
      await _open(tester, _song('a'), service);

      await tester.tap(find.text('Liked songs'));
      await tester.tap(find.text(Labels.cancel));
      await tester.pumpAndSettle();

      expect(service.isLiked(_song('a')), isFalse);
      expect(find.text(Words.playlistsSaved), findsNothing);
    });

    testWidgets('Done with nothing changed saves nothing and says nothing',
        (tester) async {
      _screen(tester);
      final service = await _service();
      await _open(tester, _song('a'), service);

      await tester.tap(find.text(Labels.done));
      await tester.pumpAndSettle();

      expect(find.text(Words.playlistsSaved), findsNothing);
      expect(service.liked.items, isEmpty);
    });

    testWidgets('a tick cleared and set again keeps the song in its place',
        (tester) async {
      _screen(tester);
      final service = await _service();
      final road = service.create('Road trip')!;
      for (final id in ['a', 'b', 'c']) {
        service.add(road.id, _song(id));
      }
      final before = service.byId(road.id)!;
      await _open(tester, _song('b'), service);

      await tester.tap(find.text('Road trip'));
      await tester.pump();
      await tester.tap(find.text('Road trip'));
      await tester.pump();
      await tester.tap(find.text(Labels.done));
      await tester.pumpAndSettle();

      expect(identical(service.byId(road.id), before), isTrue);
      expect(_keys(service, road.id), ['yt:a', 'yt:b', 'yt:c']);
    });

    testWidgets('a new playlist is only made when she presses Done',
        (tester) async {
      _screen(tester);
      final service = await _service();
      await _open(tester, _song('a'), service);

      await tester.tap(find.text(Labels.newPlaylist));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '  Late   night ');
      await tester.tap(find.byTooltip(Labels.createPlaylist));
      await tester.pump();

      expect(find.text('Late night'), findsOneWidget);
      expect(find.text(Labels.newBadge), findsOneWidget);
      expect(_ticks, findsOneWidget);
      expect(service.playlists, hasLength(1));

      await tester.tap(find.text(Labels.done));
      await tester.pumpAndSettle();

      final made = service.playlists.firstWhere((p) => !p.isLiked);
      expect(made.name, 'Late night');
      expect(made.contains('yt:a'), isTrue);
    });

    testWidgets('a new playlist she unticks is never made', (tester) async {
      _screen(tester);
      final service = await _service();
      await _open(tester, _song('a'), service);

      await tester.tap(find.text(Labels.newPlaylist));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Maybe');
      await tester.tap(find.byTooltip(Labels.createPlaylist));
      await tester.pump();
      await tester.tap(find.text('Maybe'));
      await tester.pump();
      await tester.tap(find.text(Labels.done));
      await tester.pumpAndSettle();

      expect(service.playlists, hasLength(1));
    });

    testWidgets('an empty name is not added', (tester) async {
      _screen(tester);
      final service = await _service();
      await _open(tester, _song('a'), service);

      await tester.tap(find.text(Labels.newPlaylist));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byTooltip(Labels.createPlaylist));
      await tester.pump();

      expect(find.text(Labels.newBadge), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('is a bottom sheet on a phone', (tester) async {
      _screen(tester, width: 400, height: 800);
      final service = await _service();

      await _open(tester, _song('a'), service);

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('is a dialog on a wide window', (tester) async {
      _screen(tester, width: 1200, height: 900);
      final service = await _service();

      await _open(tester, _song('a'), service);

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
    });
  });
}
