import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'app.dart';
import 'services/library_service.dart';
import 'services/stats_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/server_api.dart';
import 'services/server_config.dart';
import 'services/secure_token_store.dart';
import 'services/connection_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fonts ship inside the app (assets/google_fonts). Never reach for the network.
  GoogleFonts.config.allowRuntimeFetching = false;

  // just_audio has no built-in Windows/Linux backend — this registers
  // media_kit as the backend for those platforms only. Android/iOS/macOS
  // are left alone since just_audio already supports them natively.
  JustAudioMediaKit.ensureInitialized();

  // just_audio_background (lock-screen / notification controls) is built
  // on audio_service, which only supports Android, iOS, and macOS — NOT
  // Windows or Linux. Initializing it on desktop throws. PlayerService
  // mirrors this same platform check when deciding how to load tracks.
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.swarved.audio',
      androidNotificationChannelName: 'SwarVed playback',
      androidNotificationOngoing: true,
    );
  }

  final statsService = StatsService();
  await statsService.load();

  final libraryService = LibraryService();
  await libraryService.restoreLastLibrary();

  const serverConfig = ServerConfig();
  final tokenStore = SecureTokenStore();
  final serverApi = ServerApi(
    config: serverConfig,
    tokenStore: tokenStore,
  );

  final connectionService = ConnectionService(
    api: serverApi,
    tokenStore: tokenStore,
  );
  await connectionService.load();

  runApp(SwarVedApp(
    statsService: statsService,
    libraryService: libraryService,
    serverConfig: serverConfig,
    serverApi: serverApi,
    connectionService: connectionService,
  ));
}
