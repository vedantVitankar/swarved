import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/library_service.dart';
import '../../services/player_service.dart';
import '../../services/welcome_service.dart';
import '../../tutorial/tutorial_controller.dart';
import '../../tutorial/tutorial_intro.dart';
import '../../tutorial/tutorial_spotlight.dart';
import 'welcome_screen.dart';

/// Puts the welcome screen over the app, and after it the first-time intro
/// on Home. The app is built underneath from the start, so when the welcome
/// fades away it is simply there.
///
/// Behind the welcome, Home waits blank. When the welcome is done the
/// greeting types itself in the middle of the screen, glides up to its
/// place, and the rest of Home fades in around it. Then the tour begins:
/// Home dims, she presses play on the tutorial's song, and each part of
/// Home lights up in turn while it plays.
///
/// For now the welcome shows on every launch, while it is being perfected.
/// Remembering that she has seen it goes in [_welcoming]: start it false
/// for someone who has been welcomed before, and the intro never runs
/// either.
class WelcomeGate extends StatefulWidget {
  final Widget child;

  const WelcomeGate({super.key, required this.child});

  @override
  State<WelcomeGate> createState() => _WelcomeGateState();
}

class _WelcomeGateState extends State<WelcomeGate> {
  bool _welcoming = true;
  late final TutorialController _tutorial = TutorialController(
    stage: _welcoming ? TutorialStage.blank : TutorialStage.off,
    tour: true,
  );

  @override
  void dispose() {
    _tutorial.dispose();
    super.dispose();
  }

  void _welcomeDone() {
    setState(() => _welcoming = false);
    // The song was prepared while she read the welcome. If it isn't ready
    // or isn't there, the tour carries on without it. A fresh app has no
    // music folder, so the tour also takes her to the Library to choose one.
    final welcome = context.read<WelcomeService>();
    _tutorial.start(
      song: welcome.tutorialSong,
      addFolder: welcome.settings.tutorial.alwaysAskForFolder || _noFolder(),
    );
  }

  LibraryService? _library() {
    try {
      return context.read<LibraryService>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  /// Whether she has no music folder yet. Where there is no library to ask,
  /// the answer is no.
  bool _noFolder() {
    final library = _library();
    return library != null && library.rootPath == null;
  }

  /// Whether Home has no folders. Where there is no library to ask, the
  /// answer is no.
  bool _foldersEmpty() => _library()?.byFolder.isEmpty ?? false;

  Widget _tour() {
    final song = _tutorial.song;
    final player = song == null ? null : context.read<PlayerService>();
    return TutorialSpotlight(
      controller: _tutorial,
      captions: context.read<WelcomeService>().settings.tutorial.captions,
      playback: player,
      songIsPlaying: song == null
          ? null
          : () => player!.current?.id == song.track.id && player.isPlaying,
      foldersEmpty: _foldersEmpty,
      library: _library(),
      folderPath: () => _library()?.rootPath,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TutorialScope(
      controller: _tutorial,
      child: ListenableBuilder(
        listenable: _tutorial,
        builder: (context, _) {
          // Nothing underneath can be focused or read out while the welcome
          // or the intro covers it. The child keeps its place, so it keeps
          // its state.
          final covered = _welcoming || _tutorial.active;
          return Stack(
            fit: StackFit.expand,
            children: [
              ExcludeFocus(
                excluding: covered,
                child: ExcludeSemantics(
                  excluding: covered,
                  child: widget.child,
                ),
              ),
              if (_tutorial.opening) TutorialIntro(controller: _tutorial),
              if (_tutorial.touring) _tour(),
              if (_welcoming) WelcomeScreen(onDone: _welcomeDone),
            ],
          );
        },
      ),
    );
  }
}
