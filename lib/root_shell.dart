import 'package:flutter/material.dart';
import 'screens/home/home_screen.dart';
import 'theme/colors.dart';
import 'widgets/mini_player_bar.dart';

class RootShell extends StatelessWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.base,
      body: HomeScreen(),
      bottomNavigationBar: MiniPlayerBar(),
    );
  }
}
