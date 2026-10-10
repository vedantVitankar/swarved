import 'package:flutter/material.dart';
import '../models/tutorial_song.dart';
import 'tutorial_step.dart';

/// Where the first-time tutorial on Home has got to. A new stage only ever
/// follows the one before; [off] is a Home with no tutorial at all.
///
/// blank, typing, gliding and revealing are the opening; touring is the
/// spotlight tour over the song; finished is Home as it always is.
enum TutorialStage { off, blank, typing, gliding, revealing, touring, finished }

/// The state of the tutorial on Home. It only says what stage it is in,
/// which step is lit and what may be showing; the screens draw the rest.
class TutorialController extends ChangeNotifier {
  TutorialStage _stage;
  bool _homeVisible = true;
  bool _noteShown;
  TutorialSong? _song;
  List<TutorialStep> _steps = tutorialSteps(withSong: false);
  int _stepIndex = 0;
  final Map<TutorialStep, GlobalKey> _keys = {};

  /// With [tour] false the tutorial is only the opening, and the opening's
  /// end is the end. The app turns the tour on.
  final bool tour;

  /// Home puts this on its greeting, so the opening can glide the typed
  /// greeting to exactly where the real one sits.
  final GlobalKey greetingKey = GlobalKey(debugLabel: 'tutorial greeting');

  TutorialController({TutorialStage stage = TutorialStage.off, this.tour = false})
      : _stage = stage,
        _noteShown = stage == TutorialStage.off;

  TutorialStage get stage => _stage;

  /// The opening is under way: Home is covered and takes no taps.
  bool get opening =>
      _stage == TutorialStage.blank ||
      _stage == TutorialStage.typing ||
      _stage == TutorialStage.gliding ||
      _stage == TutorialStage.revealing;

  bool get touring => _stage == TutorialStage.touring;

  /// Anything of the tutorial is still going: Home is covered.
  bool get active => opening || touring;

  /// The greeting and the blocks around it may show. Before the opening
  /// they wait, laid out but invisible.
  bool get blocksVisible =>
      _stage == TutorialStage.off ||
      _stage == TutorialStage.revealing ||
      _stage == TutorialStage.touring ||
      _stage == TutorialStage.finished;

  bool get greetingVisible => blocksVisible;

  /// With a tutorial song the song comes first, alone: she presses play, and
  /// only then does the rest of Home appear.
  bool get songFirst => _song != null && tour;

  /// The song's card may show. It comes with the greeting.
  bool get songVisible => blocksVisible;

  /// The rest of Home (subline, chips, folders, mini player and navigation
  /// bar) may show. With the song first, that is once she has pressed play.
  bool get restVisible => switch (_stage) {
        TutorialStage.off || TutorialStage.finished => true,
        TutorialStage.revealing => !songFirst,
        TutorialStage.touring => !songFirst || _stepIndex > 0,
        _ => false,
      };

  /// The home note stays out of the tutorial. It fades in once the tutorial
  /// is over and Home is on screen, and after that it is always there.
  bool get noteVisible => _noteShown;

  bool get homeVisible => _homeVisible;

  /// The song the tutorial plays, or null when there is none.
  TutorialSong? get song => _song;

  /// Home shows the tutorial's song on its card, not the song of the day,
  /// while the tutorial runs.
  bool get songOnHome => _song != null && active;

  List<TutorialStep> get steps => _steps;

  int get stepIndex => _stepIndex;

  /// The step that is lit, or null outside the tour.
  TutorialStep? get step => touring ? _steps[_stepIndex] : null;

  /// A key for the part of the screen a step lights up. Home and the
  /// shell put it on the right widget; the spotlight measures it.
  GlobalKey keyFor(TutorialStep step) =>
      _keys.putIfAbsent(step, () => GlobalKey(debugLabel: 'tutorial ${step.name}'));

  /// The key for a navigation tab, or null for the tabs the tour doesn't
  /// stop at.
  GlobalKey? navKey(int tab) => switch (tab) {
        1 => keyFor(TutorialStep.search),
        2 => keyFor(TutorialStep.library),
        3 => keyFor(TutorialStep.us),
        _ => null,
      };

  /// The tab Home's shell should be showing: the Library while she is asked
  /// to choose a folder, Home at every other time.
  int get wantedTab =>
      step == TutorialStep.addFolder ? libraryTab : homeTab;

  static const int homeTab = 0;
  static const int libraryTab = 2;

  /// The welcome has gone: begin typing. With a [song] the tour includes
  /// pressing play and the mini player; without one it carries on silent.
  /// With [addFolder] it also takes her to the Library to choose a folder.
  void start({TutorialSong? song, bool addFolder = false}) {
    if (_stage != TutorialStage.blank) return;
    _song = song;
    _steps = tutorialSteps(withSong: song != null, addFolder: addFolder);
    _stepIndex = 0;
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

  /// The opening is over: on to the tour, or, with none, to the end.
  void finish() {
    if (_stage != TutorialStage.revealing) return;
    _go(tour && _steps.isNotEmpty ? TutorialStage.touring : TutorialStage.finished);
  }

  /// On to the next step, and after the last one the tutorial is over.
  void advance() {
    if (_stage != TutorialStage.touring) return;
    if (_stepIndex + 1 < _steps.length) {
      _stepIndex++;
      notifyListeners();
    } else {
      _go(TutorialStage.finished);
    }
  }

  /// Leaves the tour from wherever it is.
  void skip() {
    if (_stage != TutorialStage.touring) return;
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
/// fails: with no tutorial in the tree, [maybeOf] is null and everything
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

  /// For event handlers and keys, which must not subscribe.
  static TutorialController? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<TutorialScope>()?.notifier;
}
