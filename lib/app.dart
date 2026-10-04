import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'root_shell.dart';
import 'services/library_service.dart';
import 'services/player_service.dart';
import 'services/stats_service.dart';
import 'theme/app_theme.dart';
import 'widgets/text_scale_scope.dart';

class SwarVedApp extends StatelessWidget {
  final StatsService statsService;
  final LibraryService libraryService;

  const SwarVedApp({
    super.key,
    required this.statsService,
    required this.libraryService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: statsService),
        ChangeNotifierProvider.value(value: libraryService),
        ChangeNotifierProvider(create: (_) => PlayerService(statsService)),
      ],
      child: MaterialApp(
        title: 'SwarVed',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        builder: (context, child) => TextScaleScope(child: child!),
        home: const RootShell(),
      ),
    );
  }
}
