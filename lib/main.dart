import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'app.dart';
import 'services/library_service.dart';
import 'services/overlay_artwork.dart';
import 'services/playlist_puller.dart';
import 'services/smtc_windows_session.dart';
import 'services/system_media_controls.dart';
import 'services/voice_progress_reporter.dart';
import 'services/voice_service.dart';
import 'services/playlist_reporter.dart';
import 'services/playlist_service.dart';
import 'services/playlist_store.dart';
import 'services/stats_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/server_api.dart';
import 'services/server_config.dart';
import 'utils/app_profile.dart';
import 'services/secure_token_store.dart';
import 'services/connection_service.dart';
import 'services/stream_endpoint.dart';
import 'services/saved_songs_index.dart';
import 'services/song_saver.dart';
import 'services/content_cache.dart';
import 'services/content_service.dart';
import 'services/content_source.dart';
import 'services/content_sync.dart';
import 'services/media_cache.dart';
import 'services/tutorial_song_service.dart';
import 'services/welcome_service.dart';

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

  // Windows has its own media overlay (the panel the keyboard's media keys
  // bring up). just_audio_background does not reach it, so this does. If it
  // cannot start, the app simply goes without it.
  SystemMediaControls? systemControls;
  if (Platform.isWindows) {
    final session = await SmtcWindowsSession.start();
    if (session != null) {
      systemControls = SystemMediaControls(
        session: session,
        localArtwork: overlayArtworkFor,
      );
    }
  }

  final statsService = StatsService();
  await statsService.load();

  final libraryService = LibraryService();
  await libraryService.restoreLastLibrary();

  final serverConfig = ServerConfig(profile: AppProfile.current);
  final tokenStore = SecureTokenStore();
  final serverApi = ServerApi(
    config: serverConfig,
    tokenStore: tokenStore,
  );

  final streamEndpoint = StreamEndpoint(
    config: serverConfig,
    tokenStore: tokenStore,
  );

  final connectionService = ConnectionService(
    api: serverApi,
    tokenStore: tokenStore,
  );
  await connectionService.load();

  final savedSongsIndex = SavedSongsIndex();
  await savedSongsIndex.load();
  final songSaver = SongSaver(
    config: serverConfig,
    tokenStore: tokenStore,
    index: savedSongsIndex,
  );

  // His notes: first what ships inside the app, then the copy kept from the
  // last time the server sent them, so everything is there at once. The
  // server is asked once the first screen is up.
  final contentService = ContentService();
  await contentService.load();
  // His playlists ride along with the content: read only, and updated the
  // moment he publishes.
  final playlistService = PlaylistService(
    store: FilePlaylistStore(profile: AppProfile.current),
  );
  await playlistService.load();
  void showPushedPlaylists() => playlistService.setPushed([
        for (final pushed in contentService.pushedPlaylists) pushed.playlist,
      ]);
  contentService.addListener(showPushedPlaylists);
  showPushedPlaylists();
  final mediaCache = MediaCache(config: serverConfig, tokenStore: tokenStore);
  final contentSync = ContentSync(
    source: ServerContentSource(config: serverConfig, tokenStore: tokenStore),
    cache: FileContentCache(profile: AppProfile.current),
    content: contentService,
    onMedia: (names, fromServer) => mediaCache.sync(names, tidy: fromServer),
  );
  await contentSync.loadCache();
  // Her playlists follow her to every device: this reads what her other
  // devices reported and merges it in, and the reporter sends hers a few
  // seconds after each change (which is also how he sees them in the admin).
  final playlistPuller = PlaylistPuller(
    config: serverConfig,
    tokenStore: tokenStore,
    playlists: playlistService,
  )..start();
  final playlistReporter = PlaylistReporter(
    config: serverConfig,
    tokenStore: tokenStore,
    playlists: playlistService,
  )..start();

  // A token saved in Us should get the content moving at once, not after the
  // sync has finished resting from "no token".
  connectionService.addListener(() {
    if (connectionService.hasToken) {
      contentSync.poke();
      playlistPuller.poke();
      playlistReporter.poke();
    }
  });

  // His recordings, played between songs when the content says so. Only the
  // ones already on the phone are used, so music never waits on a download.
  final voiceReporter = VoiceProgressReporter(
    config: serverConfig,
    tokenStore: tokenStore,
  );
  final voiceService = VoiceInterludeService(
    settings: () => contentService.voices,
    onPhone: mediaCache.existing,
    // One that is next in line but missing is fetched for next time.
    download: (name) => unawaited(mediaCache.fileFor(name)),
    // The admin site marks each recording Played or Waiting from this.
    report: (last, played) => unawaited(voiceReporter.report(last, played)),
  );
  // The admin site should show where this phone has got to as soon as the
  // content is here, not only after the next voice has played.
  contentService.addListener(() => unawaited(voiceService.syncProgress()));
  unawaited(voiceService.syncProgress());

  final welcomeService = WelcomeService(songService: TutorialSongService());
  await welcomeService.load();

  runApp(SwarVedApp(
    statsService: statsService,
    libraryService: libraryService,
    serverConfig: serverConfig,
    serverApi: serverApi,
    streamEndpoint: streamEndpoint,
    connectionService: connectionService,
    savedSongsIndex: savedSongsIndex,
    songSaver: songSaver,
    playlistService: playlistService,
    contentService: contentService,
    welcomeService: welcomeService,
    mediaCache: mediaCache,
    voiceService: voiceService,
    systemControls: systemControls,
  ));

  // While the app is open it hears about each publish at once. In the
  // background it asks nothing, and on return it catches up first.
  contentSync.start();
  AppLifecycleListener(
    onHide: contentSync.pause,
    onShow: () {
      contentSync.resume();
      playlistPuller.poke();
    },
  );
}
