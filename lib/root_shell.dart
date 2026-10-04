import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'content/labels.dart';
import 'content/words.dart';
import 'screens/home/home_screen.dart';
import 'screens/us/us_screen.dart';
import 'services/library_service.dart';
import 'theme/colors.dart';
import 'widgets/coming_soon.dart';
import 'widgets/mini_player_bar.dart';
import 'widgets/swar_nav_bar.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final hasLibrary =
        context.select<LibraryService, bool>((l) => l.rootPath != null);

    // Before a folder is chosen the preview shows the empty state on its
    // own, with no tabs and no mini player.
    if (!hasLibrary) {
      return const Scaffold(
        backgroundColor: AppColors.base,
        body: HomeScreen(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.base,
      body: IndexedStack(
        index: _tab,
        children: const [
          HomeScreen(),
          ComingSoon(title: Labels.navSearch, message: Words.searchSoon),
          ComingSoon(title: Labels.navLibrary, message: Words.librarySoon),
          UsScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayerBar(),
          SwarNavBar(
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
        ],
      ),
    );
  }
}
