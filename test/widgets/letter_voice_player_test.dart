import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swarved/content/words.dart';
import 'package:swarved/services/clip_engine.dart';
import 'package:swarved/services/letter_voice_controller.dart';
import 'package:swarved/widgets/panel/letter_voice_player.dart';

class _Engine implements ClipEngine {
  final StreamController<ClipStatus> events =
      StreamController<ClipStatus>.broadcast(sync: true);
  final List<String> calls = [];

  @override
  Stream<ClipStatus> get clipStatus => events.stream;

  @override
  Future<void> openClip(
    File file, {
    required String title,
    required String artist,
  }) async =>
      calls.add('open');

  @override
  Future<void> playClip() async => calls.add('play');

  @override
  Future<void> pauseClip() async => calls.add('pause');

  @override
  Future<void> seekClip(Duration to) async => calls.add('seek:${to.inSeconds}');

  @override
  Future<void> closeClip() async => calls.add('close');
}

void main() {
  late _Engine engine;

  LetterVoiceController make({File? file}) => LetterVoiceController(
        engine: engine,
        fetch: (_) async => file ?? File('/tmp/0123456789abcdef.mp3'),
        file: '0123456789abcdef.mp3',
        title: 'Letter',
        artist: 'Ved',
      );

  Future<void> show(WidgetTester tester, LetterVoiceController voice) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LetterVoicePlayer(controller: voice)),
        ),
      );

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => engine = _Engine());

  testWidgets('starts with a play button and a slider that cannot be moved',
      (tester) async {
    final voice = make();
    await show(tester, voice);

    expect(find.text(Words.letterPlayVoice), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
    expect(find.text('00:00'), findsNWidgets(2));
    expect(find.byTooltip('Play'), findsOneWidget);
  });

  testWidgets('pressing play starts the recording, and the button turns '
      'into pause', (tester) async {
    final voice = make();
    await show(tester, voice);

    await tester.tap(find.byTooltip('Play'));
    await tester.pump();
    await tester.pump();

    expect(engine.calls, ['open', 'play']);
    expect(find.byTooltip('Pause'), findsOneWidget);
    voice.dispose();
  });

  testWidgets('the slider and the times follow the recording', (tester) async {
    final voice = make();
    await show(tester, voice);
    await tester.tap(find.byTooltip('Play'));
    await tester.pump();
    await tester.pump();

    engine.events.add(const ClipStatus(
      position: Duration(seconds: 30),
      duration: Duration(seconds: 90),
      playing: true,
    ));
    await tester.pump();

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.max, 90000);
    expect(slider.value, 30000);
    expect(slider.onChanged, isNotNull);
    expect(find.text('00:30'), findsOneWidget);
    expect(find.text('01:30'), findsOneWidget);
    voice.dispose();
  });

  testWidgets('letting go of the slider seeks once', (tester) async {
    final voice = make();
    await show(tester, voice);
    await tester.tap(find.byTooltip('Play'));
    await tester.pump();
    await tester.pump();
    engine.events.add(const ClipStatus(
      position: Duration.zero,
      duration: Duration(seconds: 100),
      playing: true,
    ));
    await tester.pump();

    final slider = find.byType(Slider);
    await tester.drag(slider, Offset(tester.getSize(slider).width / 2, 0));
    await tester.pump();

    final seeks = engine.calls.where((c) => c.startsWith('seek:')).toList();
    expect(seeks, hasLength(1));
    voice.dispose();
  });

  testWidgets('a recording that is not on the phone says so', (tester) async {
    final voice = LetterVoiceController(
      engine: engine,
      fetch: (_) async => null,
      file: '0123456789abcdef.mp3',
      title: 'Letter',
      artist: 'Ved',
    );
    await show(tester, voice);

    await tester.tap(find.byTooltip('Play'));
    await tester.pump();
    await tester.pump();

    expect(find.text(Words.letterVoiceMissing), findsOneWidget);
    expect(engine.calls, isEmpty);
  });
}
