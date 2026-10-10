import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/utils/track_key.dart';

Track _local(
  String title,
  String artist,
  int seconds, {
  String path = '/music/a.mp3',
}) {
  return Track(
    filePath: path,
    title: title,
    artist: artist,
    album: '',
    duration: Duration(seconds: seconds),
    folder: 'music',
  );
}

void main() {
  group('stableHash', () {
    // These values were worked out by a separate program running the same
    // steps. If they ever change, every local song in every saved playlist
    // would lose its place, so they must never change.
    test('gives fixed values, the same on every device', () {
      expect(stableHash(''), '811c9dc5d4de497d');
      expect(stableHash('a'), 'e40c292c35ed1714');
      expect(stableHash('tumhiho|arijitsingh|262'), 'b594fca39aec2edb');
      expect(stableHash('howbad|asal|0'), '820f2c0d27e13e45');
    });

    test('reads letters outside plain English as their UTF-8 bytes', () {
      expect(stableHash('caf\u00e9'), 'a82b5049f4130e21');
    });

    test('is always sixteen hex digits', () {
      for (final text in ['', 'a', 'a much longer piece of text | 123']) {
        expect(stableHash(text), matches(RegExp(r'^[0-9a-f]{16}$')));
      }
    });

    test('different text gives different hashes', () {
      expect(stableHash('ab'), isNot(stableHash('ba')));
    });
  });

  group('Track.playlistKey', () {
    test('a YouTube song is yt: and its video id', () {
      final track = Track.youtube(
        videoId: 'abc123',
        title: 'Song',
        artist: 'Channel',
        duration: const Duration(minutes: 4),
      );

      expect(track.playlistKey, 'yt:abc123');
      expect(track.playlistKey, track.id);
    });

    test('a local song is local: and sixteen hex digits', () {
      final key = _local('Tum Hi Ho', 'Arijit Singh', 262).playlistKey;

      expect(key, 'local:b594fca39aec2edb');
    });

    test('the same song at another path has the same key', () {
      final phone = _local('Tum Hi Ho', 'Arijit Singh', 262,
          path: '/storage/emulated/0/Music/Tum Hi Ho.mp3');
      final computer = _local('Tum Hi Ho', 'Arijit Singh', 262,
          path: r'D:\Songs\Arijit\tum_hi_ho.mp3');

      expect(phone.playlistKey, computer.playlistKey);
    });

    test('capitals, spaces and punctuation do not matter', () {
      final plain = _local('Tum Hi Ho', 'Arijit Singh', 262);
      final fussy = _local('  tum hi ho! ', 'ARIJIT  singh', 262);

      expect(fussy.playlistKey, plain.playlistKey);
    });

    test('a fraction of a second does not matter', () {
      final whole = _local('Tum Hi Ho', 'Arijit Singh', 262);
      final fraction = Track(
        filePath: '/music/b.mp3',
        title: 'Tum Hi Ho',
        artist: 'Arijit Singh',
        album: '',
        duration: const Duration(seconds: 262, milliseconds: 600),
        folder: 'music',
      );

      expect(fraction.playlistKey, whole.playlistKey);
    });

    test('another artist, title or length is another song', () {
      final base = _local('Tum Hi Ho', 'Arijit Singh', 262).playlistKey;

      expect(_local('Tum Hi Ho', 'Mithoon', 262).playlistKey, isNot(base));
      expect(_local('Tum Hi', 'Arijit Singh', 262).playlistKey, isNot(base));
      expect(
        _local('Tum Hi Ho', 'Arijit Singh', 300).playlistKey,
        isNot(base),
      );
    });

    test('a song with no tags still gets a steady key', () {
      final first = _local('Nothing', 'Unknown artist', 0);
      final again = _local('Nothing', 'Unknown artist', 0, path: '/x/y.mp3');

      expect(first.playlistKey, 'local:d2ed37d75d7b442f');
      expect(again.playlistKey, first.playlistKey);
    });

    test('Hindi titles that differ stay different', () {
      final a = _local('\u0924\u0941\u092e', 'x', 100);
      final b = _local('\u0924\u092e', 'x', 100);

      expect(a.playlistKey, isNot(b.playlistKey));
    });

    test('a local key never looks like a YouTube key', () {
      final key = _local('A', 'B', 1).playlistKey;

      expect(key.startsWith(localKeyPrefix), isTrue);
      expect(key.startsWith(youtubeKeyPrefix), isFalse);
    });

    test('leaves Track.id alone', () {
      final track = _local('A', 'B', 1, path: '/music/a.mp3');

      expect(track.id, '/music/a.mp3');
    });
  });
}
