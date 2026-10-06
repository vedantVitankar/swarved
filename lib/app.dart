import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'root_shell.dart';
import 'services/library_service.dart';
import 'services/player_service.dart';
import 'services/stats_service.dart';
import 'services/server_api.dart';
import 'services/server_config.dart';
import 'theme/app_theme.dart';
import 'widgets/text_scale_scope.dart';
import 'services/connection_service.dart';

class SwarVedApp extends StatelessWidget {
  final StatsService statsService;
  final LibraryService libraryService;
  final ServerConfig serverConfig;
  final ServerApi serverApi;
  final ConnectionService connectionService;

  const SwarVedApp({
    super.key,
    required this.statsService,
    required this.libraryService,
    required this.serverConfig,
    required this.serverApi,
    required this.connectionService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: statsService),
        ChangeNotifierProvider.value(value: libraryService),
        ChangeNotifierProvider(create: (_) => PlayerService(statsService)),
        Provider.value(value: serverConfig),
        Provider.value(value: serverApi),
        ChangeNotifierProvider.value(value: connectionService),
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
