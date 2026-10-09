import 'package:flutter/material.dart';
import '../../tutorial/tutorial_controller.dart';
import '../../tutorial/tutorial_intro.dart';
import 'welcome_screen.dart';

/// Puts the welcome screen over the app, and after it the first-time intro
/// on Home. The app is built underneath from the start, so when the welcome
/// fades away it is simply there.
///
/// Behind the welcome, Home waits blank. When the welcome is done the
/// greeting types itself in the middle of the screen, glides up to its
/// place, and the rest of Home fades in around it.
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
  );

  @override
  void dispose() {
    _tutorial.dispose();
    super.dispose();
  }

  void _welcomeDone() {
    setState(() => _welcoming = false);
    _tutorial.start();
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
              if (_tutorial.active) TutorialIntro(controller: _tutorial),
              if (_welcoming) WelcomeScreen(onDone: _welcomeDone),
            ],
          );
        },
      ),
    );
  }
}
