import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'root_shell.dart';
import 'services/library_service.dart';
import 'services/player_service.dart';
import 'services/search_service.dart';
import 'services/stats_service.dart';
import 'services/server_api.dart';
import 'services/server_config.dart';
import 'theme/app_theme.dart';
import 'widgets/text_scale_scope.dart';
import 'services/connection_service.dart';
import 'services/stream_endpoint.dart';

class SwarVedApp extends StatelessWidget {
  final StatsService statsService;
  final LibraryService libraryService;
  final ServerConfig serverConfig;
  final ServerApi serverApi;
  final ConnectionService connectionService;
  final StreamEndpoint streamEndpoint;

  const SwarVedApp({
    super.key,
    required this.statsService,
    required this.libraryService,
    required this.serverConfig,
    required this.serverApi,
    required this.connectionService,
    required this.streamEndpoint,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: statsService),
        ChangeNotifierProvider.value(value: libraryService),
        ChangeNotifierProvider(
          create: (_) => PlayerService(statsService, streamEndpoint),
        ),
        Provider.value(value: serverConfig),
        Provider.value(value: serverApi),
        ChangeNotifierProvider.value(value: connectionService),
        ChangeNotifierProvider(create: (_) => SearchService(api: serverApi)),
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
