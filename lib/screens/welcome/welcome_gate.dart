import 'package:flutter/material.dart';
import 'welcome_screen.dart';

/// Puts the welcome screen over the app. The app is built underneath from the
/// start, so when the welcome fades away it is simply there.
///
/// For now the welcome shows on every launch, while it is being perfected.
/// Remembering that she has seen it goes in [_welcoming]: start it false
/// for someone who has been welcomed before.
class WelcomeGate extends StatefulWidget {
  final Widget child;

  const WelcomeGate({super.key, required this.child});

  @override
  State<WelcomeGate> createState() => _WelcomeGateState();
}

class _WelcomeGateState extends State<WelcomeGate> {
  bool _welcoming = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Nothing underneath can be focused or read out while the welcome
        // covers it. The child keeps its place, so it keeps its state.
        ExcludeFocus(
          excluding: _welcoming,
          child: ExcludeSemantics(
            excluding: _welcoming,
            child: widget.child,
          ),
        ),
        if (_welcoming)
          WelcomeScreen(onDone: () => setState(() => _welcoming = false)),
      ],
    );
  }
}
