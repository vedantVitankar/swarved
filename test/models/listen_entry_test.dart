import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/listen_entry.dart';

void main() {
  group('ListenEntry JSON', () {
    test('survives a full encode and decode round-trip', () {
      final original = ListenEntry(
        trackPath: '/music/love/song.mp3',
        title: 'Song',
        artist: 'Artist',
        playedAt: DateTime(2026, 10, 5, 12, 30, 15),
        listened: const Duration(seconds: 95),
      );

      final stored = jsonEncode(original.toJson());
      final restored = ListenEntry.fromJson(
        jsonDecode(stored) as Map<String, dynamic>,
      );

      expect(restored.trackPath, original.trackPath);
      expect(restored.title, original.title);
      expect(restored.artist, original.artist);
      expect(restored.playedAt.isAtSameMomentAs(original.playedAt), isTrue);
      expect(restored.listened, original.listened);
    });
  });
}
