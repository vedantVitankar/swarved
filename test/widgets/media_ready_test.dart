import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:swarved/models/memory.dart';
import 'package:swarved/services/media_cache.dart';
import 'package:swarved/services/secure_token_store.dart';
import 'package:swarved/services/server_config.dart';
import 'package:swarved/widgets/media_ready.dart';
import 'package:swarved/widgets/panel/photo_notes_section.dart';

class _FakeTokenStore implements TokenStore {
  @override
  Future<String?> readToken() async => null;

  @override
  Future<void> writeToken(String value) async {}

  @override
  Future<void> deleteToken() async {}
}

/// A cache whose answer to "is it on the phone" the test decides.
class _Cache extends MediaCache {
  _Cache() : super(config: const ServerConfig(), tokenStore: _FakeTokenStore());

  final Set<String> here = {};

  @override
  bool isReady(String name) => here.contains(name);

  void land(String name) {
    here.add(name);
    notifyListeners();
  }
}

const _photo = '0123456789abcdef.jpg';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('mediaReady', () {
    testWidgets('holds nothing back where there is no cache', (tester) async {
      late bool ready;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            ready = mediaReady(context, [_photo]);
            return const SizedBox();
          },
        ),
      );
      expect(ready, isTrue);
    });

    testWidgets('waits for every file, ignores nulls, and redraws when the '
        'last one lands', (tester) async {
      final cache = _Cache();
      final seen = <bool>[];
      await tester.pumpWidget(
        ChangeNotifierProvider<MediaCache>.value(
          value: cache,
          child: Builder(
            builder: (context) {
              seen.add(mediaReady(context, [_photo, null]));
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen.last, isFalse);

      cache.land(_photo);
      await tester.pump();

      expect(seen.last, isTrue);
    });

    testWidgets('nothing to wait for is ready', (tester) async {
      late bool ready;
      await tester.pumpWidget(
        ChangeNotifierProvider<MediaCache>.value(
          value: _Cache(),
          child: Builder(
            builder: (context) {
              ready = mediaReady(context, [null]);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(ready, isTrue);
    });
  });

  group('PhotoNotesSection', () {
    testWidgets('keeps a photo note back until its photo is on the phone', (
      tester,
    ) async {
      final cache = _Cache();
      final memories = [
        Memory(date: DateTime(2026, 1, 1), caption: 'No picture'),
        Memory(date: DateTime(2026, 2, 1), caption: 'Waits', image: _photo),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MediaCache>.value(
            value: cache,
            child: Scaffold(
              body: SingleChildScrollView(
                child: PhotoNotesSection(title: '', memories: memories),
              ),
            ),
          ),
        ),
      );

      expect(find.text('No picture'), findsOneWidget);
      expect(find.text('Waits'), findsNothing);
    });
  });
}
