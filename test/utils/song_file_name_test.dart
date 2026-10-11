import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/utils/song_file_name.dart';

void main() {
  group('songFileName', () {
    test('joins artist and title', () {
      expect(songFileName('Arijit Singh', 'Kesariya'),
          'Arijit Singh - Kesariya.mp3');
    });

    test('leaves out a missing artist or title', () {
      expect(songFileName('', 'Kesariya'), 'Kesariya.mp3');
      expect(songFileName('Arijit Singh', ''), 'Arijit Singh.mp3');
      expect(songFileName('  ', ' '), 'Song.mp3');
    });

    test('replaces characters a file name cannot hold', () {
      expect(
          songFileName('AC/DC', 'Who Made Who?'), 'AC DC - Who Made Who.mp3');
      expect(
          songFileName('A', 'B: <C> "D" | E * F \\ G'), 'A - B C D E F G.mp3');
    });

    test('removes control characters and extra spaces', () {
      expect(songFileName('A\u0007  B', 'C\nD'), 'A B - C D.mp3');
    });

    test('does not start or end with dots or spaces', () {
      expect(songFileName('...', ' Song. '), 'Song.mp3');
      expect(songFileName('Artist.', 'Title...'), 'Artist - Title.mp3');
      expect(songFileName('Artist', '...'), 'Artist.mp3');
    });

    test('keeps letters from any language', () {
      expect(songFileName('Zoë', 'तुम हो'), 'Zoë - तुम हो.mp3');
    });

    test('never goes over the byte limit, even with wide letters', () {
      final long = 'तुम' * 200;
      final name = songFileName(long, long);

      expect(utf8.encode(name).length, lessThanOrEqualTo(210));
      expect(name.endsWith('.mp3'), isTrue);
    });

    test('a name Windows reserves gets an underscore', () {
      expect(songFileName('', 'CON'), '_CON.mp3');
      expect(songFileName('', 'nul'), '_nul.mp3');
      expect(songFileName('', 'Console'), 'Console.mp3');
    });
  });

  group('numberedFileName', () {
    test('puts the number before the extension', () {
      expect(numberedFileName('A - B.mp3', 2), 'A - B (2).mp3');
    });

    test('keeps dots inside the name', () {
      expect(numberedFileName('A. B - C.mp3', 3), 'A. B - C (3).mp3');
    });

    test('copes with a name without an extension', () {
      expect(numberedFileName('Song', 2), 'Song (2)');
    });
  });

  group('safeFolderName', () {
    test('keeps an ordinary playlist name', () {
      expect(safeFolderName('Slow dances'), 'Slow dances');
    });

    test('replaces characters a folder name cannot hold', () {
      expect(safeFolderName('Road trip: Goa/Pune?'), 'Road trip Goa Pune');
    });

    test('does not start or end with dots or spaces', () {
      expect(safeFolderName('  ..Mornings.. '), 'Mornings');
    });

    test('a name with nothing usable becomes Playlist', () {
      expect(safeFolderName(''), 'Playlist');
      expect(safeFolderName('???'), 'Playlist');
    });

    test('a name Windows reserves gets an underscore', () {
      expect(safeFolderName('con'), '_con');
    });

    test('a very long name is cut to fit', () {
      expect(utf8.encode(safeFolderName('a' * 500)).length, lessThanOrEqualTo(200));
    });
  });
}
