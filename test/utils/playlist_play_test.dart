import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/playlist_item.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/utils/playlist_play.dart';
import 'package:swarved/utils/playlist_resolve.dart';

ResolvedItem _line(String id, {required bool available}) {
  final item = PlaylistItem(
    key: 'yt:$id',
    title: 'Song $id',
    artist: 'Chan',
    duration: const Duration(seconds: 100),
    addedAt: DateTime.utc(2026),
  );
  final track = available
      ? Track.youtube(
          videoId: id,
          title: 'Song $id',
          artist: 'Chan',
          duration: const Duration(seconds: 100),
        )
      : null;
  return ResolvedItem(item, track);
}

void main() {
  group('playableIndexOf', () {
    test('is the line number when every song can be played', () {
      final lines = [
        _line('a', available: true),
        _line('b', available: true),
        _line('c', available: true),
      ];
      expect(playableIndexOf(lines, 0), 0);
      expect(playableIndexOf(lines, 2), 2);
    });

    test('does not count songs that are not on this device', () {
      final lines = [
        _line('a', available: true),
        _line('b', available: false),
        _line('c', available: false),
        _line('d', available: true),
      ];
      expect(playableIndexOf(lines, 0), 0);
      expect(playableIndexOf(lines, 3), 1);
    });

    test('is null for a song that cannot be played', () {
      final lines = [_line('a', available: false)];
      expect(playableIndexOf(lines, 0), isNull);
    });

    test('is null for a line that does not exist', () {
      final lines = [_line('a', available: true)];
      expect(playableIndexOf(lines, -1), isNull);
      expect(playableIndexOf(lines, 1), isNull);
      expect(playableIndexOf(const [], 0), isNull);
    });

    test('matches the position in the list of playable songs', () {
      final lines = [
        _line('a', available: false),
        _line('b', available: true),
        _line('c', available: false),
        _line('d', available: true),
      ];
      final playable = playableTracks(lines);
      expect(playable[playableIndexOf(lines, 1)!].videoId, 'b');
      expect(playable[playableIndexOf(lines, 3)!].videoId, 'd');
    });
  });
}
