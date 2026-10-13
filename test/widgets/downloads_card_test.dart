import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:swarved/screens/us/downloads_card.dart';
import 'package:swarved/services/content_service.dart';
import 'package:swarved/services/media_cache.dart';
import 'package:swarved/services/secure_token_store.dart';
import 'package:swarved/services/server_config.dart';

class _NoToken implements TokenStore {
  @override
  Future<String?> readToken() async => null;

  @override
  Future<void> writeToken(String value) async {}

  @override
  Future<void> deleteToken() async {}
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
  }

  Widget app(MediaCache cache) {
    return MultiProvider(
      providers: [
        Provider<MediaCache>.value(value: cache),
        ChangeNotifierProvider<ContentService>.value(
          value: ContentService(loader: () async => '{}'),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: DownloadsCard())),
    );
  }

  MediaCache cacheIn(Directory dir) {
    return MediaCache(
      config: const ServerConfig(),
      tokenStore: _NoToken(),
      client: MockClient((_) async => http.Response('', 500)),
      directory: () async => dir,
    );
  }

  testWidgets('shows nothing when no files are kept', (tester) async {
    final dir = Directory.systemTemp.createTempSync('swarved_downloads');
    addTearDown(() => dir.deleteSync(recursive: true));

    await tester.pumpWidget(app(cacheIn(dir)));
    await settle(tester);

    expect(find.text('On this phone'), findsNothing);
  });

  testWidgets('shows what is kept, and Delete clears it', (tester) async {
    final dir = Directory.systemTemp.createTempSync('swarved_downloads');
    addTearDown(() => dir.deleteSync(recursive: true));
    final folder = Directory(p.join(dir.path, 'media'))..createSync();
    File(p.join(folder.path, '0123456789abcdef.jpg'))
        .writeAsBytesSync(List.filled(2 * 1024 * 1024, 1));

    await tester.pumpWidget(app(cacheIn(dir)));
    await settle(tester);

    expect(find.text('On this phone'), findsOneWidget);
    expect(find.text('1 photo or recording, 2.0 MB'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await settle(tester);

    expect(find.text('On this phone'), findsNothing);
    expect(folder.listSync(), isEmpty);
  });
}
