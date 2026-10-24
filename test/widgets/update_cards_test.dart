import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swarved/models/app_release.dart';
import 'package:swarved/screens/home/home_update_card.dart';
import 'package:swarved/screens/us/updates_card.dart';
import 'package:swarved/services/update_service.dart';

const _release = AppRelease(
  version: '1.0.1',
  build: 2,
  file: 'SwarVed-1.0.1-2.exe',
  size: 1000,
  sha256: 'a',
  notes: 'A little nicer.',
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

  group('UpdateCardView', () {
    Widget card(
      UpdateStatus status, {
      AppRelease? release = _release,
      double progress = 0,
      VoidCallback? onUpdate,
    }) {
      return wrap(UpdateCardView(
        status: status,
        release: release,
        progress: progress,
        onUpdate: onUpdate ?? () {},
      ));
    }

    testWidgets('shows nothing unless there is something to install',
        (tester) async {
      for (final status in [
        UpdateStatus.idle,
        UpdateStatus.checking,
        UpdateStatus.upToDate,
        UpdateStatus.checkFailed,
      ]) {
        await tester.pumpWidget(card(status));
        expect(find.text('Something new for us'), findsNothing,
            reason: '$status');
      }
      await tester.pumpWidget(card(UpdateStatus.available, release: null));
      expect(find.text('Something new for us'), findsNothing);
    });

    testWidgets('offers the update, with his note, and a tap installs',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        card(UpdateStatus.available, onUpdate: () => taps++),
      );

      expect(find.text('Something new for us'), findsOneWidget);
      expect(find.textContaining('version 1.0.1'), findsOneWidget);
      expect(find.text('A little nicer.'), findsOneWidget);

      await tester.tap(find.text('Update now'));
      expect(taps, 1);
    });

    testWidgets('leaves out his note when there is none', (tester) async {
      const plain = AppRelease(
        version: '1.0.1',
        build: 2,
        file: 'SwarVed-1.0.1-2.exe',
        size: 1000,
        sha256: 'a',
      );
      await tester.pumpWidget(card(UpdateStatus.available, release: plain));
      expect(find.text('Something new for us'), findsOneWidget);
      expect(find.text('A little nicer.'), findsNothing);
    });

    testWidgets('shows how far the download is, with no button',
        (tester) async {
      await tester.pumpWidget(card(UpdateStatus.downloading, progress: 0.42));

      expect(find.text('Getting it ready... 42%'), findsOneWidget);
      expect(find.text('Update now'), findsNothing);
      final bar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator));
      expect(bar.value, 0.42);
    });

    testWidgets('says it is opening once the installer has started',
        (tester) async {
      await tester.pumpWidget(card(UpdateStatus.installing, progress: 1));

      expect(find.text('Opening it now...'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator));
      expect(bar.value, isNull);
    });

    testWidgets('after a failure it says so and offers another try',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        card(UpdateStatus.downloadFailed, onUpdate: () => taps++),
      );

      expect(find.textContaining('did not work'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(taps, 1);
    });
  });

  group('UpdatesCardView', () {
    Widget card(UpdateStatus status,
        {String? version = '1.0.0', VoidCallback? onCheck}) {
      return wrap(UpdatesCardView(
        version: version,
        status: status,
        onCheck: onCheck ?? () {},
      ));
    }

    testWidgets('shows the version and checks when asked', (tester) async {
      var checks = 0;
      await tester.pumpWidget(card(UpdateStatus.idle, onCheck: () => checks++));

      expect(find.text('App version'), findsOneWidget);
      expect(find.text('Version 1.0.0'), findsOneWidget);
      await tester.tap(find.text('Check for updates'));
      expect(checks, 1);
    });

    testWidgets('leaves out the version until it is known', (tester) async {
      await tester.pumpWidget(card(UpdateStatus.idle, version: null));
      expect(find.textContaining('Version'), findsNothing);
    });

    testWidgets('says how the last check went', (tester) async {
      final lines = {
        UpdateStatus.checking: 'Looking for something new...',
        UpdateStatus.upToDate: 'You have the latest version',
        UpdateStatus.checkFailed: 'Could not check right now',
        UpdateStatus.available: 'A new version is waiting on Home',
        UpdateStatus.downloadFailed: 'A new version is waiting on Home',
      };
      for (final entry in lines.entries) {
        await tester.pumpWidget(card(entry.key));
        expect(find.text(entry.value), findsOneWidget, reason: '${entry.key}');
      }
    });

    testWidgets('cannot be tapped while it is busy', (tester) async {
      var checks = 0;
      for (final status in [
        UpdateStatus.checking,
        UpdateStatus.downloading,
        UpdateStatus.installing,
      ]) {
        await tester.pumpWidget(card(status, onCheck: () => checks++));
        await tester.tap(find.text('Check for updates'), warnIfMissed: false);
      }
      expect(checks, 0);
    });
  });
}
