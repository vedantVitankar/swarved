import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swarved/models/save_problem.dart';
import 'package:swarved/models/youtube_result.dart';
import 'package:swarved/services/saved_songs_index.dart';
import 'package:swarved/services/secure_token_store.dart';
import 'package:swarved/services/server_config.dart';
import 'package:swarved/services/song_saver.dart';
import 'package:swarved/services/song_writer.dart';

class _FakeTokenStore implements TokenStore {
  _FakeTokenStore(this.token, {this.throws = false});

  String? token;
  final bool throws;

  @override
  Future<String?> readToken() async {
    if (throws) throw StateError('storage failed');
    return token;
  }

  @override
  Future<void> writeToken(String value) async => token = value;

  @override
  Future<void> deleteToken() async => token = null;
}

class _FailingWriter implements SongWriter {
  _FailingWriter(this.problem);

  final SaveProblem problem;

  @override
  Future<String> write({
    required File source,
    required Directory folder,
    required String fileName,
  }) async {
    throw SongWriteException(problem);
  }
}

class _ForgetfulIndex extends SavedSongsIndex {
  @override
  Future<void> record(String videoId, String path) async {
    throw Exception('storage failed');
  }
}

const _song = YoutubeResult(
  id: 'sJV8kbT1MEU',
  title: 'Kesariya',
  artist: 'Arijit Singh',
  thumbnailUrl: 'https://lh3.googleusercontent.com/a=w120-h120-l90-rj',
);

const _bytes = [10, 20, 30, 40, 50, 60];

http.StreamedResponse _ok({List<int> body = _bytes, int? length}) {
  return http.StreamedResponse(
    Stream.value(body),
    200,
    contentLength: length ?? body.length,
  );
}

Stream<List<int>> _dropsAfterFirstChunk() async* {
  yield [1, 2, 3];
  throw http.ClientException('connection lost');
}

Stream<List<int>> _goesQuietAfterFirstChunk() async* {
  yield [1, 2, 3];
  await Future<void>.delayed(const Duration(milliseconds: 400));
  yield [4, 5, 6];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late Directory library;
  late Directory temp;
  late SavedSongsIndex index;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    root = Directory.systemTemp.createTempSync('swarved_saver_test');
    library = Directory(p.join(root.path, 'library'))..createSync();
    temp = Directory(p.join(root.path, 'temp'))..createSync();
    index = SavedSongsIndex();
    await index.load();
  });

  tearDown(() {
    root.deleteSync(recursive: true);
  });

  SongSaver saverFor(
    MockClientStreamHandler handler, {
    String? token = 'secret',
    SongWriter? writer,
    SavedSongsIndex? savedIndex,
    Duration responseTimeout = const Duration(seconds: 5),
    Duration stallTimeout = const Duration(seconds: 5),
  }) {
    return SongSaver(
      config: const ServerConfig(),
      tokenStore: _FakeTokenStore(token),
      index: savedIndex ?? index,
      writer: writer,
      client: MockClient.streaming(handler),
      tempFolder: () async => temp,
      responseTimeout: responseTimeout,
      stallTimeout: stallTimeout,
    );
  }

  Future<SaveOutcome> run(SongSaver saver) =>
      saver.save(_song, folderPath: library.path);

  SaveProblem? problemOf(SaveOutcome outcome) =>
      outcome is SaveFailed ? outcome.problem : null;

  List<String> namesIn(Directory dir) =>
      dir.listSync().map((e) => p.basename(e.path)).toList()..sort();

  group('SongSaver.save: the good path', () {
    test('saves the song as Artist - Title.mp3', () async {
      final outcome = await run(saverFor((_, __) async => _ok()));

      final expected = p.join(library.path, 'Arijit Singh - Kesariya.mp3');
      expect(outcome, isA<SaveDone>());
      expect((outcome as SaveDone).path, expected);
      expect(File(expected).readAsBytesSync(), _bytes);
    });

    test('asks the server for the song, with the token and the details',
        () async {
      late http.BaseRequest seen;
      await run(saverFor((request, _) async {
        seen = request;
        return _ok();
      }));

      expect(seen.method, 'GET');
      expect(seen.url.path, '/api/export');
      expect(seen.url.queryParameters['id'], 'sJV8kbT1MEU');
      expect(seen.url.queryParameters['title'], 'Kesariya');
      expect(seen.url.queryParameters['artist'], 'Arijit Singh');
      expect(seen.url.queryParameters['cover'], _song.thumbnailUrl);
      expect(seen.headers['X-Token'], 'secret');
    });

    test('remembers the song, so it counts as saved', () async {
      await run(saverFor((_, __) async => _ok()));

      expect(index.isSaved('sJV8kbT1MEU'), isTrue);
    });

    test('leaves no temporary file in the app and none in the library',
        () async {
      await run(saverFor((_, __) async => _ok()));

      expect(namesIn(temp), isEmpty);
      expect(namesIn(library), ['Arijit Singh - Kesariya.mp3']);
    });

    test('reports progress up to the full size', () async {
      final seen = <(int, int?)>[];
      await saverFor((_, __) async => _ok()).save(
        _song,
        folderPath: library.path,
        onProgress: (received, total) => seen.add((received, total)),
      );

      expect(seen, isNotEmpty);
      expect(seen.last, (_bytes.length, _bytes.length));
    });

    test('still counts as saved when the index cannot be written', () async {
      final outcome = await run(
        saverFor((_, __) async => _ok(), savedIndex: _ForgetfulIndex()),
      );

      expect(outcome, isA<SaveDone>());
      expect(File((outcome as SaveDone).path).existsSync(), isTrue);
    });
  });

  group('SongSaver.save: duplicates', () {
    test('a song saved before is not downloaded again', () async {
      final existing = File(p.join(library.path, 'Old.mp3'))
        ..writeAsBytesSync([1]);
      final known = SavedSongsIndex();
      await known.load();
      await known.record(_song.id, existing.path);

      final outcome = await run(saverFor(
        (_, __) async => fail('no request expected'),
        savedIndex: known,
      ));

      expect(outcome, isA<SaveAlreadyThere>());
      expect((outcome as SaveAlreadyThere).path, existing.path);
    });

    test('a saved song whose file was deleted is saved again', () async {
      final known = SavedSongsIndex();
      await known.load();
      await known.record(_song.id, p.join(library.path, 'deleted.mp3'));

      final outcome =
          await run(saverFor((_, __) async => _ok(), savedIndex: known));

      expect(outcome, isA<SaveDone>());
    });

    test('tapping twice downloads once and shares the result', () async {
      var requests = 0;
      final saver = saverFor((_, __) async {
        requests++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return _ok();
      });

      final results = await Future.wait([run(saver), run(saver)]);

      expect(requests, 1);
      expect(results.every((r) => r is SaveDone), isTrue);
      expect(namesIn(library), ['Arijit Singh - Kesariya.mp3']);
    });

    test('a different song with the same name gets a number', () async {
      await run(saverFor((_, __) async => _ok()));
      const other = YoutubeResult(
        id: 'nbwLp_9Pn-c',
        title: 'Kesariya',
        artist: 'Arijit Singh',
      );

      final outcome = await saverFor((_, __) async => _ok())
          .save(other, folderPath: library.path);

      expect((outcome as SaveDone).path,
          p.join(library.path, 'Arijit Singh - Kesariya (2).mp3'));
      expect(namesIn(library).length, 2);
    });
  });

  group('SongSaver.save: before any download', () {
    test('no saved token stops without a request', () async {
      final outcome = await run(saverFor(
        (_, __) async => fail('no request expected'),
        token: null,
      ));

      expect(problemOf(outcome), SaveProblem.noToken);
    });

    test('a blank token counts as none', () async {
      final outcome = await run(saverFor(
        (_, __) async => fail('no request expected'),
        token: '   ',
      ));

      expect(problemOf(outcome), SaveProblem.noToken);
    });

    test('a token storage failure is reported, not thrown', () async {
      final saver = SongSaver(
        config: const ServerConfig(),
        tokenStore: _FakeTokenStore('x', throws: true),
        index: index,
        client:
            MockClient.streaming((_, __) async => fail('no request expected')),
        tempFolder: () async => temp,
      );

      expect(problemOf(await run(saver)), SaveProblem.unexpected);
    });

    test('a folder that is gone stops without a request', () async {
      final saver = saverFor((_, __) async => fail('no request expected'));

      final outcome = await saver.save(
        _song,
        folderPath: p.join(root.path, 'missing'),
      );

      expect(problemOf(outcome), SaveProblem.folderMissing);
    });
  });

  group('SongSaver.save: what the server says', () {
    Future<SaveProblem?> problemForStatus(int status) async {
      final outcome = await run(saverFor(
        (_, __) async => http.StreamedResponse(Stream.value([1]), status),
      ));
      expect(namesIn(library), isEmpty);
      expect(namesIn(temp), isEmpty);
      return problemOf(outcome);
    }

    test('401 and 403 mean the token was rejected', () async {
      expect(await problemForStatus(401), SaveProblem.unauthorized);
      expect(await problemForStatus(403), SaveProblem.unauthorized);
    });

    test('404 means the video is gone', () async {
      expect(await problemForStatus(404), SaveProblem.unavailable);
    });

    test('429 means the server is busy', () async {
      expect(await problemForStatus(429), SaveProblem.serverBusy);
    });

    test('server errors mean it could not prepare the song', () async {
      for (final status in [500, 502, 503, 504, 507]) {
        expect(await problemForStatus(status), SaveProblem.serverTrouble,
            reason: '$status');
      }
    });

    test('any other answer is unexpected', () async {
      expect(await problemForStatus(400), SaveProblem.unexpected);
      expect(await problemForStatus(302), SaveProblem.unexpected);
    });
  });

  group('SongSaver.save: when the connection fails', () {
    test('offline: the server cannot be reached', () async {
      final socket = await run(saverFor(
        (_, __) async => throw const SocketException('no route'),
      ));
      final client = await run(saverFor(
        (_, __) async => throw http.ClientException('offline'),
      ));

      expect(problemOf(socket), SaveProblem.unreachable);
      expect(problemOf(client), SaveProblem.unreachable);
    });

    test('an answer that never comes is a timeout', () async {
      final outcome = await run(saverFor(
        (_, __) async {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          return _ok();
        },
        responseTimeout: const Duration(milliseconds: 50),
      ));

      expect(problemOf(outcome), SaveProblem.timeout);
    });

    test('killed mid-download: nothing is saved and nothing is left behind',
        () async {
      final outcome = await run(saverFor(
        (_, __) async => http.StreamedResponse(
          _dropsAfterFirstChunk(),
          200,
          contentLength: 6,
        ),
      ));

      expect(problemOf(outcome), SaveProblem.connectionLost);
      expect(namesIn(library), isEmpty);
      expect(namesIn(temp), isEmpty);
      expect(index.isSaved(_song.id), isFalse);
    });

    test('a download that goes quiet is given up on', () async {
      final outcome = await run(saverFor(
        (_, __) async => http.StreamedResponse(
          _goesQuietAfterFirstChunk(),
          200,
          contentLength: 6,
        ),
        stallTimeout: const Duration(milliseconds: 80),
      ));

      expect(problemOf(outcome), SaveProblem.connectionLost);
      expect(namesIn(library), isEmpty);
      expect(namesIn(temp), isEmpty);
    });

    test('a download cut short is not saved as a broken song', () async {
      final outcome = await run(saverFor(
        (_, __) async => _ok(body: [1, 2, 3], length: 6),
      ));

      expect(problemOf(outcome), SaveProblem.connectionLost);
      expect(namesIn(library), isEmpty);
      expect(namesIn(temp), isEmpty);
    });

    test('an empty answer is not saved', () async {
      final outcome = await run(saverFor(
        (_, __) async => http.StreamedResponse(const Stream.empty(), 200),
      ));

      expect(problemOf(outcome), SaveProblem.unexpected);
      expect(namesIn(library), isEmpty);
    });
  });

  group('SongSaver.save: when writing fails', () {
    test('a full device is reported and the temporary file removed', () async {
      final outcome = await run(saverFor(
        (_, __) async => _ok(),
        writer: _FailingWriter(SaveProblem.diskFull),
      ));

      expect(problemOf(outcome), SaveProblem.diskFull);
      expect(namesIn(temp), isEmpty);
      expect(index.isSaved(_song.id), isFalse);
    });

    test('a refused write is reported', () async {
      final outcome = await run(saverFor(
        (_, __) async => _ok(),
        writer: _FailingWriter(SaveProblem.cannotWrite),
      ));

      expect(problemOf(outcome), SaveProblem.cannotWrite);
    });

    test('a folder that vanishes during the download is reported', () async {
      final outcome = await run(saverFor(
        (_, __) async {
          library.deleteSync(recursive: true);
          return _ok();
        },
      ));

      expect(problemOf(outcome), SaveProblem.folderMissing);
      expect(namesIn(temp), isEmpty);
    });
  });

  group('SongSaver.save: housekeeping', () {
    test('removes temporary files an earlier killed save left behind',
        () async {
      final stale = File(p.join(temp.path, 'swarved_save_old.part'))
        ..writeAsBytesSync([1])
        ..setLastModifiedSync(
            DateTime.now().subtract(const Duration(hours: 2)));
      final fresh = File(p.join(temp.path, 'swarved_save_new.part'))
        ..writeAsBytesSync([1]);
      final other = File(p.join(temp.path, 'something_else.part'))
        ..writeAsBytesSync([1])
        ..setLastModifiedSync(
            DateTime.now().subtract(const Duration(hours: 2)));

      await run(saverFor((_, __) async => _ok()));

      expect(stale.existsSync(), isFalse);
      expect(fresh.existsSync(), isTrue);
      expect(other.existsSync(), isTrue);
    });
  });
}
