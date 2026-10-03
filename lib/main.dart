import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'app.dart';
import 'services/library_service.dart';
import 'services/stats_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(SwarVedApp(
    statsService: statsService,
    libraryService: libraryService,
  ));
}