import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swarved/models/save_problem.dart';
import 'package:swarved/models/youtube_result.dart';
import 'package:swarved/services/save_controller.dart';
import 'package:swarved/services/saved_songs_index.dart';
import 'package:swarved/services/song_saver.dart';

const _id = 'aaaaaaaaaaa';

YoutubeResult _song() =>
    const YoutubeResult(id: _id, title: 'Song', artist: 'Singer');

/// A controller wired to a pretend saver. Like the real saver, the pretend
/// one records a finished song in the index.
class _Setup {
  _Setup({this.folder = '/music'}) {
    index = SavedSongsIndex(fileExists: (_) => true);
    controller = SaveController(
      save: _save,
      index: index,
      folderPath: () => folder,
      onSaved: (path) async {
        listed.add(path);
        if (listFails) throw StateError('cannot list');
      },
    );
  }

  String? folder;
  bool listFails = false;
  late final SavedSongsIndex index;
  late final SaveController controller;
  final listed = <String>[];
  int calls = 0;
  void Function(int received, int? total)? progress;

  /// When set, the save waits for this before finishing.
  Completer<SaveOutcome>? gate;
  SaveOutcome result = const SaveDone('/music/Singer - Song.mp3');

  Future<SaveOutcome> _save(
    YoutubeResult song, {
    required String folderPath,
    void Function(int received, int? total)? onProgress,
  }) async {
    calls++;
    progress = onProgress;
    final pending = gate;
    final outcome = pending == null ? result : await pending.future;
    if (outcome is SaveDone) await index.record(song.id, outcome.path);
    return outcome;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('a song nobody touched is idle', () {
    final setup = _Setup();

    expect(setup.controller.viewOf(_id), (SaveStage.idle, null));
  });

  test('saving shows progress, then saved, and the file is listed', () async {
    final setup = _Setup()..gate = Completer<SaveOutcome>();

    final future = setup.controller.save(_song());
    expect(setup.controller.viewOf(_id), (SaveStage.saving, null));

    setup.progress!(50, 100);
    expect(setup.controller.viewOf(_id), (SaveStage.saving, 50));

    setup.gate!.complete(const SaveDone('/music/a.mp3'));
    final outcome = await future;

    expect(outcome, isA<SaveDone>());
    expect(setup.listed, ['/music/a.mp3']);
    expect(setup.controller.viewOf(_id), (SaveStage.saved, null));
  });

  test('listeners hear about a new percent, not about every chunk', () async {
    final setup = _Setup()..gate = Completer<SaveOutcome>();
    var heard = 0;
    setup.controller.addListener(() => heard++);

    final future = setup.controller.save(_song());
    final atStart = heard;

    setup.progress!(1, 1000);
    setup.progress!(2, 1000);
    setup.progress!(3, 1000);
    expect(heard, atStart + 1);

    setup.progress!(500, 1000);
    expect(heard, atStart + 2);

    setup.gate!.complete(const SaveDone('/music/a.mp3'));
    await future;
  });

  test('a failed save shows retry, and retrying can succeed', () async {
    final setup = _Setup()..result = const SaveFailed(SaveProblem.unreachable);

    final outcome = await setup.controller.save(_song());

    expect(outcome, isA<SaveFailed>());
    expect(setup.controller.viewOf(_id), (SaveStage.failed, null));
    expect(setup.controller.problemOf(_id), SaveProblem.unreachable);

    setup.result = const SaveDone('/music/a.mp3');
    await setup.controller.save(_song());

    expect(setup.controller.viewOf(_id), (SaveStage.saved, null));
    expect(setup.controller.problemOf(_id), isNull);
  });

  test('no library folder fails without calling the saver', () async {
    final setup = _Setup(folder: null);

    final outcome = await setup.controller.save(_song());

    expect(
      outcome,
      isA<SaveFailed>()
          .having((o) => o.problem, 'problem', SaveProblem.folderMissing),
    );
    expect(setup.calls, 0);
    expect(setup.controller.viewOf(_id), (SaveStage.failed, null));
  });

  test('a second tap while saving does nothing', () async {
    final setup = _Setup()..gate = Completer<SaveOutcome>();

    final first = setup.controller.save(_song());
    final second = await setup.controller.save(_song());

    expect(second, isNull);
    expect(setup.calls, 1);

    setup.gate!.complete(const SaveDone('/music/a.mp3'));
    await first;
  });

  test('a list that cannot be updated does not fail the save', () async {
    final setup = _Setup()..listFails = true;

    final outcome = await setup.controller.save(_song());

    expect(outcome, isA<SaveDone>());
    expect(setup.controller.viewOf(_id), (SaveStage.saved, null));
  });

  test('a song saved earlier is listed too', () async {
    final setup = _Setup()..result = const SaveAlreadyThere('/music/a.mp3');

    await setup.controller.save(_song());

    expect(setup.listed, ['/music/a.mp3']);
  });
}
