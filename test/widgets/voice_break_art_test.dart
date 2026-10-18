import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/widgets/voice_break_art.dart';

void main() {
  testWidgets('a heart in a square of the size asked for', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: VoiceBreakArt(size: 40, iconSize: 18, radius: 8),
        ),
      ),
    );

    expect(tester.getSize(find.byType(VoiceBreakArt)), const Size(40, 40));
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
