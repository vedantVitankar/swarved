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

  void _select(int index) {
    // A home note held back by the intro appears the next time Home does.
    TutorialScope.read(context)?.setHomeVisible(index == _homeTab);
    setState(() => _tab = index);
  }

  @override
  Widget build(BuildContext context) {
    final wide =
        Responsive.of(MediaQuery.sizeOf(context).width) == ScreenClass.expanded;

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
                    order: 4,
                    child: SwarNavRail(index: _tab, onChanged: _select),
                  ),
                  // Pages and the mini player share one column, so the
                  // player lines up with the page content, not the rail.
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(child: tabs),
                        const TutorialReveal(
                          order: 4,
                          child: MiniPlayerBar(padBottom: true),
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
                order: 4,
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
