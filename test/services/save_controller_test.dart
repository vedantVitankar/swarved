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
  /// [onChoose] stands in for the folder picker. Without it the controller
  /// has no way to ask for a folder.
  _Setup({
    this.folder = '/music',
    Future<String?> Function(_Setup setup)? onChoose,
  }) {
    index = SavedSongsIndex(fileExists: (_) => true);
    controller = SaveController(
      save: _save,
      index: index,
      folderPath: () => folder,
      chooseFolder: onChoose == null
          ? null
          : () {
              asked++;
              return onChoose(this);
            },
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
  int asked = 0;
  String? savedInto;
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
    savedInto = folderPath;
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

  group('asking for a folder', () {
    test('with no folder it asks, then saves into the one chosen', () async {
      final setup = _Setup(
        folder: null,
        onChoose: (self) async {
          self.folder = '/picked';
          return '/picked';
        },
      );

      final outcome = await setup.controller.save(_song());

      expect(outcome, isA<SaveDone>());
      expect(setup.asked, 1);
      expect(setup.savedInto, '/picked');
      expect(setup.controller.viewOf(_id), (SaveStage.saved, null));
    });

    test('it does not ask when there is already a folder', () async {
      final setup = _Setup(onChoose: (_) async => '/other');

      await setup.controller.save(_song());

      expect(setup.asked, 0);
      expect(setup.savedInto, '/music');
    });

    test('closing the picker leaves the song idle and saves nothing', () async {
      final setup = _Setup(folder: null, onChoose: (_) async => null);

      final outcome = await setup.controller.save(_song());

      expect(
        outcome,
        isA<SaveFailed>()
            .having((o) => o.problem, 'problem', SaveProblem.noFolder),
      );
      expect(setup.calls, 0);
      expect(setup.controller.viewOf(_id), (SaveStage.idle, null));
      expect(setup.controller.problemOf(_id), isNull);
    });

    test('a picker that breaks counts as closed', () async {
      final setup = _Setup(
        folder: null,
        onChoose: (_) async => throw StateError('no picker'),
      );

      final outcome = await setup.controller.save(_song());

      expect(
        outcome,
        isA<SaveFailed>()
            .having((o) => o.problem, 'problem', SaveProblem.noFolder),
      );
      expect(setup.calls, 0);
    });

    test('a second tap while the picker is open does nothing', () async {
      final picker = Completer<String?>();
      final setup = _Setup(folder: null, onChoose: (_) => picker.future);

      final first = setup.controller.save(_song());
      final second = await setup.controller.save(_song());

      expect(second, isNull);
      expect(setup.asked, 1);

      picker.complete(null);
      await first;
    });

    test('after a closed picker, trying again asks again', () async {
      final setup = _Setup(folder: null, onChoose: (_) async => null);

      await setup.controller.save(_song());
      await setup.controller.save(_song());

      expect(setup.asked, 2);
    });

    test('needsFolder is true only when there is no folder and a way to ask',
        () {
      final noFolder = _Setup(folder: null, onChoose: (_) async => null);
      final hasFolder = _Setup(onChoose: (_) async => null);
      final cannotAsk = _Setup(folder: null);

      expect(noFolder.controller.needsFolder, isTrue);
      expect(hasFolder.controller.needsFolder, isFalse);
      expect(cannotAsk.controller.needsFolder, isFalse);
    });
  });
}
