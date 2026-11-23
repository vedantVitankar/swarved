import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/services/clip_engine.dart';
import 'package:swarved/services/letter_voice_controller.dart';

/// Stands in for the audio player and writes down what it was asked to do.
class FakeEngine implements ClipEngine {
  final StreamController<ClipStatus> _events =
      StreamController<ClipStatus>.broadcast(sync: true);
  final List<String> calls = [];
  Object? openError;
  Completer<void>? openGate;
  File? openedFile;
  String? openedTitle;
  String? openedArtist;

  @override
  Stream<ClipStatus> get clipStatus => _events.stream;

  void emit(ClipStatus status) => _events.add(status);

  @override
  Future<void> openClip(
    File file, {
    required String title,
    required String artist,
  }) async {
    calls.add('open');
    openedFile = file;
    openedTitle = title;
    openedArtist = artist;
    await openGate?.future;
    final error = openError;
    if (error != null) throw error;
  }

  @override
  Future<void> playClip() async => calls.add('play');

  @override
  Future<void> pauseClip() async => calls.add('pause');

  @override
  Future<void> seekClip(Duration to) async => calls.add('seek:${to.inSeconds}');

  @override
  Future<void> closeClip() async => calls.add('close');
}

ClipStatus status({
  int position = 0,
  int duration = 60,
  bool playing = true,
  ClipEnd end = ClipEnd.none,
}) =>
    ClipStatus(
      position: Duration(seconds: position),
      duration: Duration(seconds: duration),
      playing: playing,
      end: end,
    );

void main() {
  late FakeEngine engine;
  late File recording;
  Future<File?> Function(String) fetchOf(File? file) =>
      (name) async => file;

  LetterVoiceController make({Future<File?> Function(String)? fetch}) =>
      LetterVoiceController(
        engine: engine,
        fetch: fetch ?? fetchOf(recording),
        file: '0123456789abcdef.mp3',
        title: 'Open when you miss me',
        artist: 'From Ved, with love',
      );

  setUp(() {
    engine = FakeEngine();
    recording = File('/tmp/0123456789abcdef.mp3');
  });

  test('starts idle, with nothing to seek in', () {
    final voice = make();
    expect(voice.phase, LetterVoicePhase.idle);
    expect(voice.canSeek, isFalse);
    expect(voice.duration, Duration.zero);
    expect(engine.calls, isEmpty);
  });

  test('pressing play opens the recording and plays it', () async {
    final voice = make();
    await voice.toggle();

    expect(engine.calls, ['open', 'play']);
    expect(engine.openedFile, recording);
    expect(engine.openedTitle, 'Open when you miss me');
    expect(engine.openedArtist, 'From Ved, with love');
    expect(voice.phase, LetterVoicePhase.playing);
  });

  test('shows loading while the recording is fetched, and ignores a second '
      'press', () async {
    final gate = Completer<File?>();
    final voice = make(fetch: (_) => gate.future);

    final first = voice.toggle();
    expect(voice.phase, LetterVoicePhase.loading);
    await voice.toggle(); // ignored
    expect(engine.calls, isEmpty);

    gate.complete(recording);
    await first;
    expect(engine.calls, ['open', 'play']);
    expect(voice.phase, LetterVoicePhase.playing);
  });

  test('a recording that is not on the phone says so and touches nothing',
      () async {
    final voice = make(fetch: fetchOf(null));
    await voice.toggle();

    expect(voice.phase, LetterVoicePhase.missing);
    expect(engine.calls, isEmpty);
  });

  test('a fetch that throws counts as missing', () async {
    final voice = make(fetch: (_) async => throw StateError('offline'));
    await voice.toggle();

    expect(voice.phase, LetterVoicePhase.missing);
    expect(engine.calls, isEmpty);
  });

  test('a recording that will not open is reported, and the player given back',
      () async {
    engine.openError = StateError('cannot decode');
    final voice = make();
    await voice.toggle();
    await Future<void>.delayed(Duration.zero);

    expect(voice.phase, LetterVoicePhase.failed);
    expect(engine.calls, ['open', 'close']);
  });

  test('after a failure or a miss, pressing again tries again', () async {
    var found = false;
    final voice = make(fetch: (_) async => found ? recording : null);
    await voice.toggle();
    expect(voice.phase, LetterVoicePhase.missing);

    found = true;
    await voice.toggle();
    expect(voice.phase, LetterVoicePhase.playing);
    expect(engine.calls, ['open', 'play']);
  });

  test('position and length follow what the player reports', () async {
    final voice = make();
    await voice.toggle();

    engine.emit(status(position: 12, duration: 90));
    expect(voice.position, const Duration(seconds: 12));
    expect(voice.duration, const Duration(seconds: 90));
    expect(voice.canSeek, isTrue);
  });

  test('the length is kept from before it starts playing', () async {
    final gate = Completer<void>();
    engine.openGate = gate;
    final voice = make();
    final start = voice.toggle();
    await Future<void>.delayed(Duration.zero);

    engine.emit(status(duration: 45, playing: false));
    expect(voice.duration, const Duration(seconds: 45));
    expect(voice.phase, LetterVoicePhase.loading); // still opening

    gate.complete();
    await start;
    expect(voice.phase, LetterVoicePhase.playing);
  });

  test('pause and continue go through the player', () async {
    final voice = make();
    await voice.toggle();

    await voice.toggle();
    expect(voice.phase, LetterVoicePhase.paused);
    expect(engine.calls, ['open', 'play', 'pause']);

    await voice.toggle();
    expect(voice.phase, LetterVoicePhase.playing);
    expect(engine.calls, ['open', 'play', 'pause', 'play']);
  });

  test('the player pausing it from outside is shown as paused', () async {
    final voice = make();
    await voice.toggle();
    engine.emit(status(position: 5, playing: false));

    expect(voice.phase, LetterVoicePhase.paused);
  });

  test('the slider seeks, kept inside the recording', () async {
    final voice = make();
    await voice.toggle();
    engine.emit(status(duration: 60));

    await voice.seek(const Duration(seconds: 20));
    await voice.seek(const Duration(seconds: 500));
    await voice.seek(const Duration(seconds: -4));

    expect(engine.calls, ['open', 'play', 'seek:20', 'seek:60', 'seek:0']);
    expect(voice.position, Duration.zero);
  });

  test('nothing can be seeked before the recording is open', () async {
    final voice = make();
    await voice.seek(const Duration(seconds: 10));

    expect(engine.calls, isEmpty);
  });

  test('at the end it goes back to the start, paused, and does not restart '
      'anything else', () async {
    final voice = make();
    await voice.toggle();
    engine.emit(status(position: 59, duration: 60));

    engine.emit(status(position: 0, duration: 60, end: ClipEnd.finished));
    await Future<void>.delayed(Duration.zero);

    expect(voice.phase, LetterVoicePhase.paused);
    expect(voice.position, Duration.zero);
    // Wound back and stopped; the player is kept, and nothing else is played.
    expect(engine.calls, ['open', 'play', 'pause', 'seek:0']);
  });

  test('events while it winds back do not make it look as if it started',
      () async {
    final voice = make();
    await voice.toggle();
    engine.emit(status(duration: 60));

    engine.emit(status(position: 0, end: ClipEnd.finished));
    // The player still says "playing" for a moment after the end.
    engine.emit(status(position: 0, playing: true));
    await Future<void>.delayed(Duration.zero);

    expect(voice.phase, LetterVoicePhase.paused);
  });

  test('after the end, pressing play plays it again from the start', () async {
    final voice = make();
    await voice.toggle();
    engine.emit(status(duration: 60));
    engine.emit(status(position: 0, end: ClipEnd.finished));
    await Future<void>.delayed(Duration.zero);

    await voice.toggle();

    expect(voice.phase, LetterVoicePhase.playing);
    expect(engine.calls.last, 'play');
    expect(engine.calls.where((c) => c == 'open').length, 1);
  });

  test('a song taking over the player ends the recording quietly', () async {
    final voice = make();
    await voice.toggle();

    engine.emit(status(playing: false, end: ClipEnd.taken));
    expect(voice.phase, LetterVoicePhase.idle);
    expect(voice.position, Duration.zero);

    // Closing the letter later must not stop the song that took over.
    voice.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(engine.calls, ['open', 'play']);
  });

  test('closing the letter stops its recording and gives the player back',
      () async {
    final voice = make();
    await voice.toggle();
    voice.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(engine.calls, ['open', 'play', 'close']);
  });

  test('closing a letter whose recording never started touches nothing',
      () async {
    final voice = make();
    voice.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(engine.calls, isEmpty);
  });

  test('closing the letter while the recording is still being fetched '
      'starts nothing', () async {
    final gate = Completer<File?>();
    final voice = make(fetch: (_) => gate.future);
    final start = voice.toggle();
    voice.dispose();
    gate.complete(recording);
    await start;

    expect(engine.calls, isEmpty);
  });

  test('closing the letter while the recording is opening gives it back and '
      'never plays it', () async {
    final gate = Completer<void>();
    engine.openGate = gate;
    final voice = make();
    final start = voice.toggle();
    await Future<void>.delayed(Duration.zero);

    voice.dispose();
    gate.complete();
    await start;
    await Future<void>.delayed(Duration.zero);

    expect(engine.calls, ['open', 'close']);
  });
}
