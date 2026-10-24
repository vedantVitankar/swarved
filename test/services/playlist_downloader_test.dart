import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swarved/models/save_problem.dart';
import 'package:swarved/models/youtube_result.dart';
import 'package:swarved/services/playlist_downloader.dart';
import 'package:swarved/services/save_controller.dart';
import 'package:swarved/services/saved_songs_index.dart';
import 'package:swarved/services/song_saver.dart';

YoutubeResult _song(String id) =>
    YoutubeResult(id: id, title: 'Song $id', artist: 'Singer');

/// A downloader over a pretend saver. Like the real saver, the pretend one
/// records a finished song in the index.
class _Setup {
  _Setup({this.root = '/music', Future<String?> Function()? choose}) {
    index = SavedSongsIndex(fileExists: (_) => true);
    controller = SaveController(
      save: _save,
      index: index,
      folderPath: () => root,
      chooseFolder: choose,
      onSaved: (_) async {},
    );
    downloader = PlaylistDownloader(
      saves: controller,
      index: index,
      makeFolder: (path) async {
        if (folderError != null) throw folderError!;
        made.add(path);
      },
    );
  }

  String? root;
  late final SavedSongsIndex index;
  late final SaveController controller;
  late final PlaylistDownloader downloader;

  final made = <String>[];
  final folders = <String>[];
  final tried = <String>[];
  Object? folderError;

  /// What each song's save ends with. A song not listed saves fine.
  final outcomes = <String, SaveOutcome>{};

  /// Runs while a song is being saved, before it finishes.
  void Function(YoutubeResult song)? duringSave;

  Future<SaveOutcome> _save(
    YoutubeResult song, {
    required String folderPath,
    void Function(int received, int? total)? onProgress,
  }) async {
    tried.add(song.id);
    folders.add(folderPath);
    duringSave?.call(song);
    final outcome = outcomes[song.id] ?? SaveDone('$folderPath/${song.id}.mp3');
    if (outcome is SaveDone) await index.record(song.id, outcome.path);
    return outcome;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves every song into a folder named after the playlist', () async {
    final setup = _Setup();

    final result = await setup.downloader.download(
      playlistId: 'p1',
      playlistName: 'Slow dances',
      songs: [_song('a'), _song('b'), _song('c')],
    );

    expect(setup.made, [p.join('/music', 'Slow dances')]);
    expect(setup.folders, everyElement(p.join('/music', 'Slow dances')));
    expect(setup.tried, ['a', 'b', 'c']);
    expect(result!.saved, 3);
    expect(result.failed, 0);
    expect(result.folderName, 'Slow dances');
    expect(result.stoppedBy, isNull);
  });

  test('makes an unsafe playlist name safe for the folder', () async {
    final setup = _Setup();

    final result = await setup.downloader.download(
      playlistId: 'p1',
      playlistName: 'Goa: the/trip?',
      songs: [_song('a')],
    );

    expect(setup.made, [p.join('/music', 'Goa the trip')]);
    expect(result!.folderName, 'Goa the trip');
  });

  test('skips songs that are saved already', () async {
    final setup = _Setup();
    await setup.index.record('b', '/music/b.mp3');

    final result = await setup.downloader.download(
      playlistId: 'p1',
      playlistName: 'Mix',
      songs: [_song('a'), _song('b'), _song('c')],
    );

    expect(setup.tried, ['a', 'c']);
    expect(result!.saved, 2);
    expect(result.alreadySaved, 1);
  });

  test('with everything saved, makes no folder and downloads nothing',
      () async {
    final setup = _Setup();
    await setup.index.record('a', '/music/a.mp3');

    final result = await setup.downloader.download(
      playlistId: 'p1',
      playlistName: 'Mix',
      songs: [_song('a')],
    );

    expect(setup.made, isEmpty);
    expect(setup.tried, isEmpty);
    expect(result!.nothingToDo, isTrue);
    expect(result.alreadySaved, 1);
  });

  test('a song that cannot be saved does not stop the others', () async {
    final setup = _Setup()
      ..outcomes['b'] = const SaveFailed(SaveProblem.unavailable);

    final result = await setup.downloader.download(
      playlistId: 'p1',
      playlistName: 'Mix',
      songs: [_song('a'), _song('b'), _song('c')],
    );

    expect(setup.tried, ['a', 'b', 'c']);
    expect(result!.saved, 2);
    expect(result.failed, 1);
    expect(result.stoppedBy, isNull);
  });

  test('a problem every song would share stops the run', () async {
    final setup = _Setup()
      ..outcomes['b'] = const SaveFailed(SaveProblem.unauthorized);

    final result = await setup.downloader.download(
      playlistId: 'p1',
      playlistName: 'Mix',
      songs: [_song('a'), _song('b'), _song('c')],
    );

    expect(setup.tried, ['a', 'b']);
    expect(result!.saved, 1);
    expect(result.stoppedBy, SaveProblem.unauthorized);
  });

  test('trying again picks up only what is missing', () async {
    final setup = _Setup()
      ..outcomes['b'] = const SaveFailed(SaveProblem.timeout);
    final songs = [_song('a'), _song('b')];

    await setup.downloader
        .download(playlistId: 'p1', playlistName: 'Mix', songs: songs);
    setup.tried.clear();
    setup.outcomes.clear();
    final again = await setup.downloader
        .download(playlistId: 'p1', playlistName: 'Mix', songs: songs);

    expect(setup.tried, ['b']);
    expect(again!.saved, 1);
    expect(again.alreadySaved, 1);
  });

  test('stopping it lets the song in flight finish, then ends', () async {
    final setup = _Setup();
    setup.duringSave = (song) {
      if (song.id == 'a') setup.downloader.cancel('p1');
    };

    final result = await setup.downloader.download(
      playlistId: 'p1',
      playlistName: 'Mix',
      songs: [_song('a'), _song('b'), _song('c')],
    );

    expect(setup.tried, ['a']);
    expect(result!.saved, 1);
    expect(result.cancelled, isTrue);
    expect(setup.downloader.isRunning('p1'), isFalse);
  });

  test('shows progress while it runs, and nothing after', () async {
    final setup = _Setup();
    final seen = <(int, int, bool)>[];
    setup.duringSave = (_) {
      final view = setup.downloader.viewOf('p1')!;
      seen.add((view.finished, view.total, view.stopping));
    };

    expect(setup.downloader.viewOf('p1'), isNull);
    await setup.downloader.download(
      playlistId: 'p1',
      playlistName: 'Mix',
      songs: [_song('a'), _song('b')],
    );

    expect(seen, [(0, 2, false), (1, 2, false)]);
    expect(setup.downloader.viewOf('p1'), isNull);
  });

  test('a second tap while it runs does nothing', () async {
    final setup = _Setup();
    Future<bool>? second;
    setup.duringSave = (song) {
      if (song.id == 'a') {
        second = setup.downloader.download(
          playlistId: 'p1',
          playlistName: 'Mix',
          songs: [_song('a'), _song('b')],
        ).then((result) => result == null);
      }
    };

    await setup.downloader.download(
      playlistId: 'p1',
      playlistName: 'Mix',
      songs: [_song('a'), _song('b')],
    );

    expect(await second, isTrue);
    expect(setup.tried, ['a', 'b']);
  });

  test('two playlists can download side by side', () async {
    final setup = _Setup();
    Future<void>? other;
    setup.duringSave = (song) {
      if (song.id == 'a') {
        other = setup.downloader.download(
          playlistId: 'p2',
          playlistName: 'Other',
          songs: [_song('z')],
        ).then((_) {});
      }
    };

    await setup.downloader.download(
      playlistId: 'p1',
      playlistName: 'Mix',
      songs: [_song('a')],
    );
    await other;

    expect(
      setup.made,
      containsAll([p.join('/music', 'Mix'), p.join('/music', 'Other')]),
    );
  });

  test('asks for the library folder first when there is none', () async {
    var asked = 0;
    final setup = _Setup(
      root: null,
      choose: () async {
        asked++;
        return '/picked';
      },
    );

    final result = await setup.downloader.download(
      playlistId: 'p1',
      playlistName: 'Mix',
      songs: [_song('a')],
    );

    // The pretend library has no way to remember the pick, so the folder is
    // made under the answer the picker gave.
    expect(asked, 1);
    expect(setup.made, [p.join('/picked', 'Mix')]);
    expect(result!.saved, 1);
  });

  test('closing the folder picker stops the run before anything happens',
      () async {
    final setup = _Setup(root: null, choose: () async => null);

    final result = await setup.downloader.download(
      playlistId: 'p1',
      playlistName: 'Mix',
      songs: [_song('a')],
    );

    expect(result!.stoppedBy, SaveProblem.noFolder);
    expect(setup.made, isEmpty);
    expect(setup.tried, isEmpty);
    expect(setup.downloader.isRunning('p1'), isFalse);
  });

  test('a folder that cannot be made is a write problem', () async {
    final setup = _Setup()
      ..folderError = const FileSystemException(
        'denied',
        '/music/Mix',
        OSError('Permission denied', 13),
      );

    final result = await setup.downloader.download(
      playlistId: 'p1',
      playlistName: 'Mix',
      songs: [_song('a')],
    );

    expect(result!.stoppedBy, SaveProblem.cannotWrite);
    expect(setup.tried, isEmpty);
    expect(setup.downloader.isRunning('p1'), isFalse);
  });

  test('counts the songs that still have no file', () async {
    final setup = _Setup();
    await setup.index.record('a', '/music/a.mp3');

    expect(
      setup.downloader.missingCount([_song('a'), _song('b'), _song('c')]),
      2,
    );
    expect(setup.downloader.missingCount([_song('a')]), 0);
  });

  test('only problems every song would share stop a run', () {
    const stops = {
      SaveProblem.noToken,
      SaveProblem.unauthorized,
      SaveProblem.unreachable,
      SaveProblem.folderMissing,
      SaveProblem.noFolder,
      SaveProblem.cannotWrite,
      SaveProblem.diskFull,
    };
    for (final problem in SaveProblem.values) {
      expect(
        PlaylistDownloader.stopsRun(problem),
        stops.contains(problem),
        reason: '$problem',
      );
    }
  });
}
