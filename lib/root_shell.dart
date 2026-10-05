import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'content/labels.dart';
import 'content/words.dart';
import 'screens/home/empty_library_state.dart';
import 'screens/home/home_screen.dart';
import 'screens/library/library_screen.dart';
import 'screens/us/us_screen.dart';
import 'services/library_service.dart';
import 'theme/colors.dart';
import 'theme/responsive.dart';
import 'widgets/coming_soon.dart';
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

  void _select(int index) => setState(() => _tab = index);

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryService>();

    // Before a folder is chosen: just the empty state, no tabs, no player.
    if (library.rootPath == null) {
      return Scaffold(
        backgroundColor: AppColors.base,
        body: EmptyLibraryState(
          problem: library.problem,
          onChoose: library.pickAndScanFolder,
          onOpenSettings: library.openPermissionSettings,
        ),
      );
    }

    final wide =
        Responsive.of(MediaQuery.sizeOf(context).width) == ScreenClass.expanded;

    final tabs = IndexedStack(
      index: _tab,
      children: const [
        HomeScreen(),
        ComingSoon(title: Labels.navSearch, message: Words.searchSoon),
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
                  SwarNavRail(index: _tab, onChanged: _select),
                  // Pages and the mini player share one column, so the
                  // player lines up with the page content, not the rail.
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(child: tabs),
                        const MiniPlayerBar(padBottom: true),
                      ],
                    ),
                  ),
                ],
              )
            : tabs,
        bottomNavigationBar: wide
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MiniPlayerBar(),
                  SwarNavBar(index: _tab, onChanged: _select),
                ],
              ),
      ),
    );
  }
}
