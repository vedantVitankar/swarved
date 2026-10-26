import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swarved/models/letter.dart';
import 'package:swarved/models/memory.dart';
import 'package:swarved/models/panel_settings.dart';
import 'package:swarved/widgets/panel/countdown_card.dart';
import 'package:swarved/widgets/panel/letters_section.dart';
import 'package:swarved/widgets/panel/photo_notes_section.dart';
import 'package:swarved/widgets/panel/pinned_note_card.dart';
import 'package:swarved/widgets/server_photo.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

  group('PinnedNoteCard', () {
    testWidgets('shows the usual heading and his words', (tester) async {
      await tester.pumpWidget(wrap(
        const PinnedNoteCard(note: PinnedNote(text: 'Happy birthday, my love')),
      ));
      expect(find.text('Pinned for you'), findsOneWidget);
      expect(find.text('Happy birthday, my love'), findsOneWidget);
      expect(find.byType(ServerPhoto), findsNothing);
    });

    testWidgets('shows his own heading instead', (tester) async {
      await tester.pumpWidget(wrap(
        const PinnedNoteCard(note: PinnedNote(text: 'Hi', label: 'Today')),
      ));
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Pinned for you'), findsNothing);
    });
  });

  group('CountdownCard', () {
    testWidgets('shows the days and the usual words', (tester) async {
      await tester.pumpWidget(wrap(const CountdownCard(label: '', days: 12)));
      expect(find.text('Until I see you'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('days'), findsOneWidget);
    });

    testWidgets('one day is a day', (tester) async {
      await tester.pumpWidget(wrap(const CountdownCard(label: '', days: 1)));
      expect(find.text('day'), findsOneWidget);
      expect(find.text('days'), findsNothing);
    });

    testWidgets('on the day itself it says Today, with his words', (tester) async {
      await tester.pumpWidget(
        wrap(const CountdownCard(label: 'Until I hold you', days: 0)),
      );
      expect(find.text('Until I hold you'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });
  });

  group('LetterTile', () {
    const open = Letter(id: 'abc12345', when: 'you miss me', body: 'Here.');
    final locked = Letter(
      id: 'def67890',
      when: 'you need a hug',
      unlocksOn: DateTime(2026, 12, 25),
      locked: true,
    );

    Widget tile(Letter letter, {bool opened = false, VoidCallback? onTap}) =>
        wrap(LetterTile(letter: letter, opened: opened, onTap: onTap));

    testWidgets('a new letter says so and opens when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(tile(open, onTap: () => taps++));
      expect(find.text('Open when you miss me'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
      expect(find.byIcon(Icons.mail_outline_rounded), findsOneWidget);

      await tester.tap(find.text('Open when you miss me'));
      expect(taps, 1);
    });

    testWidgets('an opened letter is no longer new', (tester) async {
      await tester.pumpWidget(tile(open, opened: true, onTap: () {}));
      expect(find.text('New'), findsNothing);
      expect(find.byIcon(Icons.drafts_outlined), findsOneWidget);
    });

    testWidgets('a letter not due yet shows its day and cannot be opened',
        (tester) async {
      await tester.pumpWidget(tile(locked));
      expect(find.text('Open when you need a hug'), findsOneWidget);
      expect(find.text('Opens on 25 December 2026'), findsOneWidget);
      expect(find.text('New'), findsNothing);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

      await tester.tap(find.text('Open when you need a hug'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('a locked letter with no day just shows that it is there',
        (tester) async {
      const noDay = Letter(id: 'ghi12345', when: 'soon', locked: true);
      await tester.pumpWidget(tile(noDay));
      expect(find.text('Open when soon'), findsOneWidget);
      expect(find.textContaining('Opens on'), findsNothing);
    });
  });

  group('PhotoNotesSection', () {
    final memories = [
      Memory(date: DateTime(2026, 1, 1), caption: 'First one'),
      Memory(date: DateTime(2026, 2, 1), caption: 'Second one'),
      Memory(date: DateTime(2026, 3, 1), caption: 'Third one'),
    ];

    Widget section({
      List<Memory>? list,
      String title = '',
      int? limit,
      bool saySoWhenEmpty = false,
    }) =>
        wrap(PhotoNotesSection(
          title: title,
          memories: list ?? memories,
          limit: limit,
          saySoWhenEmpty: saySoWhenEmpty,
        ));

    testWidgets('lists the newest first, under the usual title', (tester) async {
      await tester.pumpWidget(section());
      expect(find.text('Photo notes'), findsOneWidget);
      final third = tester.getTopLeft(find.text('Third one')).dy;
      final second = tester.getTopLeft(find.text('Second one')).dy;
      final first = tester.getTopLeft(find.text('First one')).dy;
      expect(third, lessThan(second));
      expect(second, lessThan(first));
    });

    testWidgets('uses his own title', (tester) async {
      await tester.pumpWidget(section(title: 'Us'));
      expect(find.text('Us'), findsOneWidget);
      expect(find.text('Photo notes'), findsNothing);
    });

    testWidgets('keeps only the newest few when there is little room',
        (tester) async {
      await tester.pumpWidget(section(limit: 2));
      expect(find.text('Third one'), findsOneWidget);
      expect(find.text('Second one'), findsOneWidget);
      expect(find.text('First one'), findsNothing);
    });

    testWidgets('with none, it says so only when asked', (tester) async {
      await tester.pumpWidget(section(list: [], saySoWhenEmpty: true));
      expect(find.text('Photo notes'), findsOneWidget);
      expect(find.textContaining('gather here'), findsOneWidget);

      await tester.pumpWidget(section(list: []));
      expect(find.text('Photo notes'), findsNothing);
      expect(find.textContaining('gather here'), findsNothing);
    });
  });
}
