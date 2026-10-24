import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/content/words.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/services/system_media_controls.dart';

class _FakePlayer extends ChangeNotifier implements MediaSessionPlayer {
  @override
  Track? current;
  @override
  bool isInterlude = false;
  @override
  bool isPlaying = false;
  @override
  bool isLoading = false;
  @override
  bool canGoNext = true;
  @override
  Duration position = Duration.zero;
  @override
  Duration duration = const Duration(minutes: 3);

  final presses = <String>[];

  @override
  Future<void> togglePlayPause() async => presses.add('toggle');
  @override
  Future<void> next() async => presses.add('next');
  @override
  Future<void> restartOrPrevious() async => presses.add('previous');

  void change(void Function() edit) {
    edit();
    notifyListeners();
  }
}

class _FakeSession implements SystemMediaSession {
  final calls = <String>[];
  final pressed = StreamController<MediaButton>.broadcast();
  Object? failWith;

  void _record(String call) {
    calls.add(call);
    if (failWith != null) throw failWith!;
  }

  @override
  Stream<MediaButton> get buttons => pressed.stream;

  @override
  Future<void> show({
    required String title,
    required String artist,
    String? album,
    String? thumbnail,
  }) async =>
      _record('show $title|$artist|${album ?? '-'}|${thumbnail ?? '-'}');

  @override
  Future<void> setStatus(SessionStatus status) async =>
      _record('status ${status.name}');

  @override
  Future<void> setTimeline({
    required Duration position,
    required Duration duration,
  }) async =>
      _record('timeline ${position.inSeconds}/${duration.inSeconds}');

  @override
  Future<void> setButtons({required bool next, required bool previous}) async =>
      _record('buttons next=$next previous=$previous');

  @override
  Future<void> dispose() async => _record('dispose');

  List<String> only(String kind) =>
      calls.where((call) => call.startsWith(kind)).toList();
}

Track _song(String id, {String? art}) => Track.youtube(
      videoId: id,
      title: 'Song $id',
      artist: 'Artist $id',
      duration: const Duration(minutes: 3),
      artworkUrl: art,
    );

void main() {
  late _FakePlayer player;
  late _FakeSession session;
  late DateTime now;
  late SystemMediaControls controls;

  SystemMediaControls build({LocalArtwork? localArtwork}) =>
      SystemMediaControls(
        session: session,
        localArtwork: localArtwork,
        clock: () => now,
      );

  setUp(() {
    player = _FakePlayer();
    session = _FakeSession();
    now = DateTime(2026, 10, 18, 12);
    controls = build();
  });

  tearDown(() => session.pressed.close());

  Future<void> settle() => pumpEventQueue();

  test('a song that plays shows its words, cover, buttons and progress',
      () async {
    controls.attach(player);
    player.change(() {
      player.current = _song('a', art: 'https://img.example.com/a.jpg');
      player.isPlaying = true;
    });
    await settle();

    expect(session.only('show'), [
      'show Song a|Artist a|-|https://img.example.com/a.jpg',
    ]);
    expect(session.only('buttons').last, 'buttons next=true previous=true');
    expect(session.only('timeline').last, 'timeline 0/180');
    expect(session.only('status').last, 'status playing');
  });

  test('nothing is shown before there is a song', () async {
    controls.attach(player);
    await settle();
    expect(session.only('show'), isEmpty);
    expect(session.only('status').last, 'status stopped');
  });

  test('pause and resume change the status, and say nothing else', () async {
    controls.attach(player);
    player.change(() {
      player.current = _song('a');
      player.isPlaying = true;
    });
    await settle();
    session.calls.clear();

    player.change(() => player.isPlaying = false);
    await settle();
    expect(session.calls, ['timeline 0/180', 'status paused']);

    session.calls.clear();
    player.change(() => player.isPlaying = true);
    await settle();
    expect(session.calls, ['timeline 0/180', 'status playing']);
  });

  test('the same state again is not sent again', () async {
    controls.attach(player);
    player.change(() {
      player.current = _song('a');
      player.isPlaying = true;
    });
    await settle();
    session.calls.clear();

    now = now.add(const Duration(seconds: 1));
    player.change(() => player.position = const Duration(seconds: 1));
    player.change(() => player.position = const Duration(milliseconds: 1200));
    await settle();
    expect(session.calls, isEmpty);
  });

  test('a seek is sent, ordinary progress is not', () async {
    controls.attach(player);
    player.change(() {
      player.current = _song('a');
      player.isPlaying = true;
    });
    await settle();
    session.calls.clear();

    // Ten seconds go by and the position follows: nothing to say.
    now = now.add(const Duration(seconds: 10));
    player.change(() => player.position = const Duration(seconds: 10));
    await settle();
    expect(session.calls, isEmpty);

    // Then she drags to 2:00.
    player.change(() => player.position = const Duration(minutes: 2));
    await settle();
    expect(session.calls, ['timeline 120/180']);
  });

  test('the next song is shown, and its own cover', () async {
    controls.attach(player);
    player.change(() {
      player.current = _song('a', art: 'https://img.example.com/a.jpg');
      player.isPlaying = true;
    });
    await settle();
    session.calls.clear();

    player.change(() => player.current = _song('b'));
    await settle();
    expect(session.only('show'), ['show Song b|Artist b|-|-'],
        reason: 'no cover: nothing is passed, so the old one can go');
  });

  test('loading shows as changing, not as playing', () async {
    controls.attach(player);
    player.change(() {
      player.current = _song('a');
      player.isPlaying = true; // stale: the player still says so
      player.isLoading = true;
    });
    await settle();
    expect(session.only('status').last, 'status changing');
  });

  test('his recording is shown in his words, with no song and no cover',
      () async {
    controls.attach(player);
    player.change(() {
      player.current = _song('a', art: 'https://img.example.com/a.jpg');
      player.isInterlude = true;
      player.isPlaying = true;
      player.duration = const Duration(seconds: 12);
    });
    await settle();

    expect(session.only('show'), [
      'show ${Words.voiceBreakTitle}|${Words.voiceBreakFrom}|-|-',
    ]);
    expect(session.only('timeline').last, 'timeline 0/12');
  });

  test('the next button is turned off when there is no next song', () async {
    controls.attach(player);
    player.change(() {
      player.current = _song('a');
      player.canGoNext = false;
    });
    await settle();
    expect(session.only('buttons').last, 'buttons next=false previous=true');

    player.change(() => player.canGoNext = true);
    await settle();
    expect(session.only('buttons').last, 'buttons next=true previous=true');
  });

  test('a cover that is not a web address is never passed on', () async {
    controls.attach(player);
    final bad = ['', 'not a url', '/just/a/path', 'ftp://x.com/a.jpg'];
    for (var i = 0; i < bad.length; i++) {
      session.calls.clear();
      player.change(() => player.current = _song('v$i', art: bad[i]));
      await settle();
      expect(session.only('show').single.endsWith('|-'), isTrue,
          reason: '"${bad[i]}" must not reach the native side');
    }
  });

  test('which addresses count as a cover', () {
    expect(SystemMediaControls.webAddress('https://a.com/x.jpg'),
        'https://a.com/x.jpg');
    expect(SystemMediaControls.webAddress('http://a.com/x.jpg'),
        'http://a.com/x.jpg');
    expect(SystemMediaControls.webAddress('  https://a.com/x.jpg '),
        'https://a.com/x.jpg');
    expect(SystemMediaControls.webAddress(null), isNull);
    expect(SystemMediaControls.webAddress('https://'), isNull);
    expect(SystemMediaControls.webAddress('file:///C:/a.jpg'), isNull);
    expect(SystemMediaControls.fileAddress('file:///C:/a.jpg'),
        'file:///C:/a.jpg');
    expect(SystemMediaControls.fileAddress('https://a.com/x.jpg'), isNull);
    expect(SystemMediaControls.fileAddress(null), isNull);
  });

  test('a song on this computer gets the cover that was inside it', () async {
    controls = build(localArtwork: (track) async => 'file:///C:/art/1.jpg');
    controls.attach(player);
    player.change(() {
      player.current = Track(
        filePath: r'C:\Music\a.mp3',
        title: 'Local',
        artist: 'Me',
        album: 'Album',
        duration: const Duration(minutes: 2),
        folder: r'C:\Music',
      );
    });
    await settle();
    expect(session.only('show'), ['show Local|Me|Album|file:///C:/art/1.jpg']);
  });

  test('a cover that cannot be prepared costs the picture, not the song',
      () async {
    controls = build(localArtwork: (track) async => throw StateError('disk'));
    controls.attach(player);
    player.change(() {
      player.current = Track(
        filePath: r'C:\Music\a.mp3',
        title: 'Local',
        artist: 'Me',
        album: '',
        duration: const Duration(minutes: 2),
        folder: r'C:\Music',
      );
    });
    await settle();
    expect(session.only('show'), ['show Local|Me|-|-']);
  });

  group('the overlay\'s buttons', () {
    setUp(() async {
      controls.attach(player);
      player.change(() => player.current = _song('a'));
      await settle();
    });

    Future<void> press(MediaButton button) async {
      session.pressed.add(button);
      await settle();
    }

    test('play starts a paused song, and does nothing to a playing one',
        () async {
      await press(MediaButton.play);
      expect(player.presses, ['toggle']);

      player.change(() => player.isPlaying = true);
      await press(MediaButton.play);
      expect(player.presses, ['toggle'], reason: 'already playing');
    });

    test('pause stops a playing song, and does nothing to a paused one',
        () async {
      await press(MediaButton.pause);
      expect(player.presses, isEmpty, reason: 'already paused');

      player.change(() => player.isPlaying = true);
      await press(MediaButton.pause);
      expect(player.presses, ['toggle']);
    });

    test('next and previous do what the app\'s own buttons do', () async {
      await press(MediaButton.next);
      await press(MediaButton.previous);
      expect(player.presses, ['next', 'previous']);
    });

    test('a button that fails does not throw', () async {
      final broken = _BrokenPlayer();
      final other = build()..attach(broken);
      session.pressed.add(MediaButton.next);
      await settle();
      expect(broken.tried, isTrue);
      await other.dispose();
    });
  });

  test('an overlay that fails never reaches the player', () async {
    session.failWith = StateError('no overlay');
    controls.attach(player);
    player.change(() {
      player.current = _song('a');
      player.isPlaying = true;
    });
    await settle();
    expect(session.only('show'), isNotEmpty, reason: 'it did try');
    // And the later updates still go through the same way.
    player.change(() => player.isPlaying = false);
    await settle();
    expect(session.only('status').last, 'status paused');
  });

  test('closing it lets go of the player and the overlay', () async {
    controls.attach(player);
    await controls.dispose();
    session.calls.clear();
    player.change(() => player.current = _song('a'));
    await settle();
    expect(session.calls, isEmpty);
  });
}

class _BrokenPlayer extends _FakePlayer {
  bool tried = false;

  @override
  Future<void> next() async {
    tried = true;
    throw StateError('cannot skip');
  }
}
