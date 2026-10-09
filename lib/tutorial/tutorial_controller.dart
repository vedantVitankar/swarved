import 'package:flutter/material.dart';

/// Where the first-time intro on Home has got to. A new stage only ever
/// follows the one before; [off] is a Home with no intro at all.
enum TutorialStage { off, blank, typing, gliding, revealing, finished }

/// The state of the intro on Home. It only says what stage it is in and
/// what may be showing; the screens draw the rest. Later stages of the
/// tutorial will slot in between [revealing] and [finished].
class TutorialController extends ChangeNotifier {
  TutorialStage _stage;
  bool _homeVisible = true;
  bool _noteShown;

  /// Home puts this on its greeting, so the intro can glide the typed
  /// greeting to exactly where the real one sits.
  final GlobalKey greetingKey = GlobalKey(debugLabel: 'tutorial greeting');

  TutorialController({TutorialStage stage = TutorialStage.off})
      : _stage = stage,
        _noteShown = stage == TutorialStage.off;

  TutorialStage get stage => _stage;

  /// The intro is under way: Home is covered and takes no taps.
  bool get active =>
      _stage != TutorialStage.off && _stage != TutorialStage.finished;

  /// The greeting and the blocks around it may show. Before the intro they
  /// wait, laid out but invisible.
  bool get blocksVisible =>
      _stage == TutorialStage.off ||
      _stage == TutorialStage.revealing ||
      _stage == TutorialStage.finished;

  bool get greetingVisible => blocksVisible;

  /// The home note stays out of the intro. It fades in once the intro is
  /// over and Home is on screen, and after that it is always there.
  bool get noteVisible => _noteShown;

  bool get homeVisible => _homeVisible;

  /// The welcome has gone: begin typing.
  void start() {
    if (_stage != TutorialStage.blank) return;
    _go(TutorialStage.typing);
  }

  void glide() {
    if (_stage != TutorialStage.typing) return;
    _go(TutorialStage.gliding);
  }

  void reveal() {
    if (_stage != TutorialStage.gliding) return;
    _go(TutorialStage.revealing);
  }

  void finish() {
    if (_stage != TutorialStage.revealing) return;
    _go(TutorialStage.finished);
  }

  /// The shell says whether the Home tab is the one on screen. A note that
  /// has been waiting appears the next time Home is.
  void setHomeVisible(bool visible) {
    if (_homeVisible == visible) return;
    _homeVisible = visible;
    if (_maybeShowNote()) notifyListeners();
  }

  void _go(TutorialStage next) {
    _stage = next;
    _maybeShowNote();
    notifyListeners();
  }

  bool _maybeShowNote() {
    if (_noteShown) return false;
    if (_stage != TutorialStage.finished || !_homeVisible) return false;
    _noteShown = true;
    return true;
  }
}

/// Hands the controller down to Home and the shell. Looking it up never
/// fails: with no intro in the tree, [maybeOf] is null and everything
/// simply shows.
class TutorialScope extends InheritedNotifier<TutorialController> {
  const TutorialScope({
    super.key,
    required TutorialController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Rebuilds the caller whenever the stage changes.
  static TutorialController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TutorialScope>()?.notifier;

  /// For event handlers, which must not subscribe.
  static TutorialController? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<TutorialScope>()?.notifier;
}
