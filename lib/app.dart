import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'root_shell.dart';
import 'screens/welcome/welcome_gate.dart';
import 'services/library_service.dart';
import 'services/playlist_service.dart';
import 'services/player_media_session.dart';
import 'services/player_service.dart';
import 'services/search_service.dart';
import 'services/stats_service.dart';
import 'services/system_media_controls.dart';
import 'services/server_api.dart';
import 'services/server_config.dart';
import 'theme/app_theme.dart';
import 'widgets/text_scale_scope.dart';
import 'services/connection_service.dart';
import 'services/stream_endpoint.dart';
import 'services/queue_prefetcher.dart';
import 'services/playlist_downloader.dart';
import 'services/save_controller.dart';
import 'services/saved_songs_index.dart';
import 'services/song_saver.dart';
import 'services/letter_service.dart';
import 'services/update_service.dart';
import 'services/content_service.dart';
import 'services/media_cache.dart';
import 'services/voice_service.dart';
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
  final PlaylistService playlistService;
  final ContentService contentService;
  final WelcomeService welcomeService;
  final MediaCache mediaCache;

  /// Looks for a newer version of the app and installs it.
  final UpdateService updateService;

  /// Which of his letters she has opened.
  final LetterService letterService;

  /// Plays his recordings between songs. Optional, so the app also runs
  /// without it.
  final VoiceInterludeService? voiceService;

  /// Shows the song and its buttons in the operating system's media overlay
  /// (Windows). Optional, so the app also runs without it.
  final SystemMediaControls? systemControls;

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
    required this.playlistService,
    required this.contentService,
    required this.welcomeService,
    required this.mediaCache,
    required this.updateService,
    required this.letterService,
    this.voiceService,
    this.systemControls,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: statsService),
        ChangeNotifierProvider.value(value: libraryService),
        ChangeNotifierProvider(
          create: (_) {
            final player = PlayerService(
              statsService,
              streamEndpoint,
              prefetcher: QueuePrefetcher(api: serverApi),
              voices: voiceService,
            );
            systemControls?.attach(PlayerMediaSession(player));
            return player;
          },
        ),
        ChangeNotifierProvider.value(value: playlistService),
        ChangeNotifierProvider.value(value: contentService),
        ChangeNotifierProvider.value(value: welcomeService),
        Provider.value(value: mediaCache),
        Provider.value(value: serverConfig),
        Provider.value(value: serverApi),
        ChangeNotifierProvider.value(value: connectionService),
        ChangeNotifierProvider.value(value: updateService),
        ChangeNotifierProvider.value(value: letterService),
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
        ChangeNotifierProvider(
          create: (context) => PlaylistDownloader(
            saves: context.read<SaveController>(),
            index: savedSongsIndex,
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
