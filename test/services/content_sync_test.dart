import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/services/content_cache.dart';
import 'package:swarved/services/content_service.dart';
import 'package:swarved/services/content_source.dart';
import 'package:swarved/services/content_sync.dart';

final _track = Track(
  filePath: '/music/Kesariya.mp3',
  title: 'Kesariya',
  artist: 'Artist',
  album: '',
  duration: const Duration(minutes: 3),
  folder: 'music',
);

String _note(String text) => '{"notes":[{"title":"Kesariya","note":"$text"}]}';

/// Answers from a list, and remembers what it was asked.
class _ScriptedSource implements ContentSource {
  _ScriptedSource(this.script);

  final List<ContentFetch> script;
  final calls = <({String? etag, bool wait})>[];

  @override
  Future<ContentFetch> fetch({
    String? etag,
    bool wait = false,
    Future<void>? abortTrigger,
  }) async {
    calls.add((etag: etag, wait: wait));
    return script.removeAt(0);
  }
}

/// Holds each request open until the test answers it, or cancels it.
class _GatedSource implements ContentSource {
  final waits = <bool>[];
  Completer<ContentFetch>? pending;

  @override
  Future<ContentFetch> fetch({
    String? etag,
    bool wait = false,
    Future<void>? abortTrigger,
  }) {
    waits.add(wait);
    final answer = pending = Completer<ContentFetch>();
    abortTrigger?.then((_) {
      if (!answer.isCompleted) {
        answer.complete(const ContentFailed(ContentFailure.aborted));
      }
    });
    return answer.future;
  }
}

class _FakeCache implements ContentCache {
  CachedContent? stored;
  final writes = <CachedContent>[];
  bool failWrites = false;

  @override
  Future<CachedContent?> read() async => stored;

  @override
  Future<void> write(CachedContent content) async {
    if (failWrites) throw Exception('disk full');
    writes.add(content);
    stored = content;
  }
}

ContentSync _sync(
  ContentSource source,
  ContentCache cache,
  ContentService content, {
  Future<void> Function(Set<String>, bool)? onMedia,
  Future<void> Function(Duration)? sleep,
}) {
  return ContentSync(
    source: source,
    cache: cache,
    content: content,
    onMedia: onMedia,
    minGap: Duration.zero,
    sleep: sleep ?? (_) async {},
  );
}

ContentService _service() => ContentService(loader: () async => '{}');

void main() {
  group('ContentSync.restAfter', () {
    test('a server that cannot be reached is tried again with growing rests',
        () {
      final rests = [
        for (var i = 1; i <= 8; i++)
          ContentSync.restAfter(ContentFailure.unavailable, i).inSeconds,
      ];
      expect(rests, [5, 10, 20, 40, 60, 60, 60, 60]);
    });

    test('a refused token or a strange answer rests half a minute', () {
      expect(
        ContentSync.restAfter(ContentFailure.unauthorized, 1),
        const Duration(seconds: 30),
      );
      expect(
        ContentSync.restAfter(ContentFailure.unexpected, 9),
        const Duration(seconds: 30),
      );
    });

    test('a cancelled request needs no rest', () {
      expect(
        ContentSync.restAfter(ContentFailure.aborted, 1),
        Duration.zero,
      );
    });
  });

  group('ContentSync.loadCache', () {
    test('applies the copy on the phone, and asks with its tag', () async {
      final cache = _FakeCache()
        ..stored = CachedContent(body: _note('From the phone.'), etag: '"v1"');
      final content = _service();
      final source = _ScriptedSource([const ContentUnchanged()]);
      final sync = _sync(source, cache, content);

      await sync.loadCache();
      expect(content.noteFor(_track)?.note, 'From the phone.');

      await sync.syncOnce();
      expect(source.calls.single.etag, '"v1"');
      expect(source.calls.single.wait, isFalse); // catching up first
    });

    test('with no copy, nothing changes', () async {
      final content = _service();
      final sync = _sync(_ScriptedSource([]), _FakeCache(), content);
      await sync.loadCache();
      expect(content.pack.notes, isEmpty);
    });

    test('a copy that is not content is ignored', () async {
      final cache = _FakeCache()
        ..stored = const CachedContent(body: 'not json', etag: '"v1"');
      final source = _ScriptedSource([const ContentUnchanged()]);
      final sync = _sync(source, cache, _service());

      await sync.loadCache();
      await sync.syncOnce();

      expect(source.calls.single.etag, isNull);
    });
  });

  group('ContentSync.syncOnce', () {
    test('new content is applied, kept, and then waited on', () async {
      final cache = _FakeCache();
      final content = _service();
      final source = _ScriptedSource([
        ContentNew(body: _note('Fresh.'), etag: '"v2"'),
        const ContentUnchanged(),
      ]);
      final sync = _sync(source, cache, content);

      await sync.syncOnce();
      expect(content.noteFor(_track)?.note, 'Fresh.');
      expect(cache.writes.single.etag, '"v2"');
      expect(cache.writes.single.body, _note('Fresh.'));

      await sync.syncOnce();
      expect(source.calls[1].etag, '"v2"');
      expect(source.calls[1].wait, isTrue); // now waits for the next publish
    });

    test('listeners hear about new content', () async {
      final content = _service();
      var told = 0;
      content.addListener(() => told++);
      final sync = _sync(
        _ScriptedSource([ContentNew(body: _note('x'), etag: '"v2"')]),
        _FakeCache(),
        content,
      );

      await sync.syncOnce();

      expect(told, 1);
    });

    test('nothing new leaves the content alone', () async {
      final content = _service()..apply(_note('Kept.'));
      final cache = _FakeCache();
      final sync = _sync(
        _ScriptedSource([const ContentUnchanged()]),
        cache,
        content,
      );

      await sync.syncOnce();

      expect(content.noteFor(_track)?.note, 'Kept.');
      expect(cache.writes, isEmpty);
    });

    test('with nothing published, the next request waits for the first',
        () async {
      final source = _ScriptedSource([
        const ContentNothingPublished(),
        const ContentNothingPublished(),
      ]);
      final sync = _sync(source, _FakeCache(), _service());

      await sync.syncOnce();
      await sync.syncOnce();

      expect(source.calls[0].wait, isFalse);
      expect(source.calls[1].wait, isTrue);
      expect(source.calls[1].etag, isNull);
    });

    test('a failure keeps the content and catches up next time', () async {
      final content = _service();
      final source = _ScriptedSource([
        ContentNew(body: _note('Good.'), etag: '"v1"'),
        const ContentFailed(ContentFailure.unavailable),
        const ContentUnchanged(),
      ]);
      final sync = _sync(source, _FakeCache(), content);

      await sync.syncOnce();
      final rest = await sync.syncOnce();
      await sync.syncOnce();

      expect(rest, const Duration(seconds: 5));
      expect(content.noteFor(_track)?.note, 'Good.');
      expect(source.calls[2].wait, isFalse); // asks at once, not waits
      expect(source.calls[2].etag, '"v1"');
    });

    test('failures in a row rest longer, and a success starts over', () async {
      final source = _ScriptedSource([
        const ContentFailed(ContentFailure.unavailable),
        const ContentFailed(ContentFailure.unavailable),
        const ContentFailed(ContentFailure.unavailable),
        const ContentUnchanged(),
        const ContentFailed(ContentFailure.unavailable),
      ]);
      final sync = _sync(source, _FakeCache(), _service());

      final rests = [
        for (var i = 0; i < 5; i++) (await sync.syncOnce()).inSeconds,
      ];

      expect(rests, [5, 10, 20, 0, 5]);
    });

    test('content that is not content counts as a failure and changes nothing',
        () async {
      final content = _service();
      final cache = _FakeCache();
      final source = _ScriptedSource([
        ContentNew(body: _note('Good.'), etag: '"v1"'),
        const ContentNew(body: 'not json', etag: '"v9"'),
        const ContentUnchanged(),
      ]);
      final sync = _sync(source, cache, content);

      await sync.syncOnce();
      final rest = await sync.syncOnce();
      await sync.syncOnce();

      expect(rest, const Duration(seconds: 30));
      expect(content.noteFor(_track)?.note, 'Good.');
      expect(cache.writes, hasLength(1)); // the bad copy was not kept
      expect(source.calls[2].etag, '"v1"'); // still the good one
    });

    test('a copy that cannot be saved does not stop the update', () async {
      final content = _service();
      final cache = _FakeCache()..failWrites = true;
      final sync = _sync(
        _ScriptedSource([ContentNew(body: _note('Live.'), etag: '"v2"')]),
        cache,
        content,
      );

      await sync.syncOnce();

      expect(content.noteFor(_track)?.note, 'Live.');
    });

    test('a cancelled request is not a failure', () async {
      final source = _ScriptedSource([
        const ContentFailed(ContentFailure.aborted),
        const ContentFailed(ContentFailure.unavailable),
      ]);
      final sync = _sync(source, _FakeCache(), _service());

      final first = await sync.syncOnce();
      final second = await sync.syncOnce();

      expect(first, Duration.zero);
      expect(second, const Duration(seconds: 5)); // the first failure
    });
  });

  group('ContentSync photos', () {
    const body = '{"memories":['
        '{"date":"2025-01-01","caption":"a","image":"0123456789abcdef.jpg"},'
        '{"date":"2025-01-02","caption":"b","image":"assets/memories/b.jpg"},'
        '{"date":"2025-01-03","caption":"c"}'
        ']}';

    test('the files a new content uses are announced as from the server',
        () async {
      final told = <(Set<String>, bool)>[];
      final sync = _sync(
        _ScriptedSource([const ContentNew(body: body, etag: '"v1"')]),
        _FakeCache(),
        _service(),
        onMedia: (names, fromServer) async => told.add((names, fromServer)),
      );

      await sync.syncOnce();

      expect(told.single.$1, {'0123456789abcdef.jpg'});
      expect(told.single.$2, isTrue);
    });

    test('the copy on the phone announces its files, but not as the server\'s',
        () async {
      final told = <(Set<String>, bool)>[];
      final cache = _FakeCache()
        ..stored = const CachedContent(body: body, etag: '"v1"');
      final sync = _sync(
        _ScriptedSource([]),
        cache,
        _service(),
        onMedia: (names, fromServer) async => told.add((names, fromServer)),
      );

      await sync.loadCache();

      expect(told.single.$1, {'0123456789abcdef.jpg'});
      expect(told.single.$2, isFalse);
    });

    test('a voice or any other file the content names is announced too',
        () async {
      final told = <Set<String>>[];
      final sync = _sync(
        _ScriptedSource([
          const ContentNew(
            body: '{"letters":[{"voice":"fedcba9876543210.m4a"}],'
                '"memories":[{"date":"2025-01-03","caption":"c",'
                '"image":"0123456789abcdef.jpg"}]}',
            etag: '"v1"',
          ),
        ]),
        _FakeCache(),
        _service(),
        onMedia: (names, _) async => told.add(names),
      );

      await sync.syncOnce();

      expect(told.single, {'0123456789abcdef.jpg', 'fedcba9876543210.m4a'});
    });
  });

  group('ContentSync running', () {
    test('asks at once, then waits, and stops asking when the app hides',
        () async {
      final source = _GatedSource();
      final sync = _sync(source, _FakeCache(), _service());

      sync.start();
      sync.start(); // the second start does nothing
      await pumpEventQueue();
      expect(source.waits, [false]);

      source.pending!.complete(const ContentUnchanged());
      await pumpEventQueue();
      expect(source.waits, [false, true]); // now holding a request open

      sync.pause(); // the app went to the background
      await pumpEventQueue();
      expect(source.waits, [false, true]); // cancelled, nothing new asked

      sync.stop();
      await pumpEventQueue();
    });

    test('on return it catches up first, then waits again', () async {
      final source = _GatedSource();
      final content = _service();
      final sync = _sync(source, _FakeCache(), content);

      sync.start();
      await pumpEventQueue();
      source.pending!.complete(const ContentUnchanged());
      await pumpEventQueue();
      sync.pause();
      await pumpEventQueue();

      sync.resume();
      await pumpEventQueue();
      expect(source.waits, [false, true, false]); // catching up

      source.pending!.complete(
        ContentNew(body: _note('While away.'), etag: '"v5"'),
      );
      await pumpEventQueue();
      expect(content.noteFor(_track)?.note, 'While away.');
      expect(source.waits, [false, true, false, true]); // waiting again

      sync.stop();
      await pumpEventQueue();
    });

    test('a publish while the app is open shows up without a restart',
        () async {
      final source = _GatedSource();
      final content = _service();
      final sync = _sync(source, _FakeCache(), content);

      sync.start();
      await pumpEventQueue();
      source.pending!.complete(
        ContentNew(body: _note('First.'), etag: '"v1"'),
      );
      await pumpEventQueue();
      expect(content.noteFor(_track)?.note, 'First.');

      // The server holds the request; he clicks Publish; it answers.
      source.pending!.complete(
        ContentNew(body: _note('Published just now.'), etag: '"v2"'),
      );
      await pumpEventQueue();
      expect(content.noteFor(_track)?.note, 'Published just now.');

      sync.stop();
      await pumpEventQueue();
    });

    test('poke ends the rest after a failure, so a saved token starts it',
        () async {
      final rest = Completer<void>(); // a rest that never ends on its own
      final source = _ScriptedSource([
        const ContentFailed(ContentFailure.unauthorized),
        ContentNew(body: _note('After the token.'), etag: '"v1"'),
      ]);
      final content = _service();
      final sync = _sync(
        source,
        _FakeCache(),
        content,
        sleep: (_) => rest.future,
      );

      sync.start();
      await pumpEventQueue();
      expect(source.calls, hasLength(1)); // failed, now resting

      sync.poke();
      await pumpEventQueue();
      expect(source.calls, hasLength(2));
      expect(content.noteFor(_track)?.note, 'After the token.');

      sync.stop();
      rest.complete();
      await pumpEventQueue();
    });

    test('poke while nothing is resting does nothing', () async {
      final source = _GatedSource();
      final sync = _sync(source, _FakeCache(), _service());

      sync.start();
      await pumpEventQueue();
      sync.poke();
      await pumpEventQueue();

      expect(source.waits, [false]);

      sync.stop();
      await pumpEventQueue();
    });

    test('resume without a pause does nothing', () async {
      final source = _GatedSource();
      final sync = _sync(source, _FakeCache(), _service());

      sync.start();
      await pumpEventQueue();
      sync.resume();
      await pumpEventQueue();

      expect(source.waits, [false]);

      sync.stop();
      await pumpEventQueue();
    });
  });
}
