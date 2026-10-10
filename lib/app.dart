import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'root_shell.dart';
import 'screens/welcome/welcome_gate.dart';
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
import 'services/queue_prefetcher.dart';
import 'services/save_controller.dart';
import 'services/saved_songs_index.dart';
import 'services/song_saver.dart';
import 'services/content_service.dart';
import 'services/welcome_service.dart';

class SwarVedApp extends StatelessWidget {
  final StatsService statsService;
  final LibraryService libraryService;
  final ServerConfig serverConfig;
  final ServerApi serverApi;
  final ConnectionService connectionService;
  final StreamEndpoint streamEndpoint;
  final SavedSongsIndex savedSongsIndex;
  final SongSaver songSaver;
  final ContentService contentService;
  final WelcomeService welcomeService;

  const SwarVedApp({
    super.key,
    required this.statsService,
    required this.libraryService,
    required this.serverConfig,
    required this.serverApi,
    required this.connectionService,
    required this.streamEndpoint,
    required this.savedSongsIndex,
    required this.songSaver,
    required this.contentService,
    required this.welcomeService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: statsService),
        ChangeNotifierProvider.value(value: libraryService),
        ChangeNotifierProvider(
          create: (_) => PlayerService(
            statsService,
            streamEndpoint,
            prefetcher: QueuePrefetcher(api: serverApi),
          ),
        ),
        ChangeNotifierProvider.value(value: contentService),
        ChangeNotifierProvider.value(value: welcomeService),
        Provider.value(value: serverConfig),
        Provider.value(value: serverApi),
        ChangeNotifierProvider.value(value: connectionService),
        ChangeNotifierProvider(create: (_) => SearchService(api: serverApi)),
        ChangeNotifierProvider(
          create: (_) => SaveController(
            save: songSaver.save,
            index: savedSongsIndex,
            folderPath: () => libraryService.rootPath,
            chooseFolder: libraryService.chooseFolder,
            onSaved: libraryService.addSavedFile,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'SwarVed',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        builder: (context, child) => TextScaleScope(child: child!),
        home: const WelcomeGate(child: RootShell()),
      ),
    );
  }
}
