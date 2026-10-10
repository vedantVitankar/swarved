import 'package:flutter/material.dart';
import 'screens/home/home_screen.dart';
import 'screens/library/library_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/us/us_screen.dart';
import 'theme/colors.dart';
import 'theme/responsive.dart';
import 'tutorial/tutorial_controller.dart';
import 'tutorial/tutorial_reveal.dart';
import 'widgets/mini_player_bar.dart';
import 'widgets/swar_nav_bar.dart';
import 'widgets/swar_nav_rail.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  static const _homeTab = 0;
  int _tab = _homeTab;

  /// The tab the tour last asked for, so it is only followed when it changes.
  int _wantedTab = _homeTab;

  void _select(int index) {
    // A home note held back by the intro appears the next time Home does.
    TutorialScope.read(context)?.setHomeVisible(index == _homeTab);
    setState(() => _tab = index);
  }

  @override
  Widget build(BuildContext context) {
    final wide =
        Responsive.of(MediaQuery.sizeOf(context).width) == ScreenClass.expanded;

    // The mini player and navigation bar fade in with the rest of Home: last
    // of the blocks, or right after the song when the song comes first.
    final tutorial = TutorialScope.maybeOf(context);
    final barOrder = tutorial != null && tutorial.songFirst ? 3 : 4;

    // The tour takes her to the Library to pick a folder, and brings her
    // back to Home afterwards.
    final wanted = tutorial?.wantedTab ?? _homeTab;
    if (wanted != _wantedTab) {
      _wantedTab = wanted;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _select(wanted);
      });
    }

    final tabs = IndexedStack(
      index: _tab,
      children: const [
        HomeScreen(),
        SearchScreen(),
        LibraryScreen(),
        UsScreen(),
      ],
    );

    // Back from any other tab goes to Home first, then leaves the app.
    return PopScope(
      canPop: _tab == _homeTab,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(_homeTab);
      },
      child: Scaffold(
        backgroundColor: AppColors.base,
        body: wide
            ? Row(
                children: [
                  TutorialReveal(
                    order: barOrder,
                    child: SwarNavRail(index: _tab, onChanged: _select),
                  ),
                  // Pages and the mini player share one column, so the
                  // player lines up with the page content, not the rail.
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(child: tabs),
                        TutorialReveal(
                          order: barOrder,
                          child: const MiniPlayerBar(padBottom: true),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : tabs,
        bottomNavigationBar: wide
            ? null
            : TutorialReveal(
                order: barOrder,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MiniPlayerBar(),
                    SwarNavBar(index: _tab, onChanged: _select),
                  ],
                ),
              ),
      ),
    );
  }
}
