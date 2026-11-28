import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/playlist_import.dart';

Map<String, Object?> _song(String id, [String title = 'T']) => {
      'id': id,
      'title': title,
      'artist': 'Chan',
      'durationSeconds': 120,
      'thumbnailUrl': 'https://i.ytimg.com/vi/$id/mqdefault.jpg',
    };

void main() {
  group('PlaylistImportAnswer.parse', () {
    test('reads the playlist and its songs, in order', () {
      final answer = PlaylistImportAnswer.parse({
        'ok': true,
        'title': ' Rainy day ',
        'songs': [_song('aaaaaaaaaaa', 'One'), _song('bbbbbbbbbbb', 'Two')],
        'skipped': 3,
        'truncated': true,
      });
      final playlist = answer.playlist!;
      expect(answer.problem, isNull);
      expect(playlist.title, 'Rainy day');
      expect([for (final s in playlist.songs) s.title], ['One', 'Two']);
      expect(playlist.songs.first.artist, 'Chan');
      expect(playlist.songs.first.duration, const Duration(seconds: 120));
      expect(playlist.skipped, 3);
      expect(playlist.truncated, isTrue);
    });

    test('a song that is listed twice, or has no id, is skipped', () {
      final answer = PlaylistImportAnswer.parse({
        'ok': true,
        'songs': [
          _song('aaaaaaaaaaa'),
          {'title': 'no id'},
          _song('aaaaaaaaaaa'),
          _song('bbbbbbbbbbb'),
        ],
      });
      expect(
        [for (final s in answer.playlist!.songs) s.id],
        ['aaaaaaaaaaa', 'bbbbbbbbbbb'],
      );
    });

    test('a missing title and counts are filled in quietly', () {
      final playlist = PlaylistImportAnswer.parse({
        'ok': true,
        'songs': [_song('aaaaaaaaaaa')],
      }).playlist!;
      expect(playlist.title, '');
      expect(playlist.skipped, 0);
      expect(playlist.truncated, isFalse);
    });

    test('an answer with no usable song is the unavailable problem', () {
      final answer = PlaylistImportAnswer.parse({
        'ok': true,
        'songs': [
          {'id': ''},
        ],
      });
      expect(answer.playlist, isNull);
      expect(answer.problem, PlaylistImportProblem.unavailable);
    });

    test('each reason the server gives becomes its problem', () {
      PlaylistImportProblem? of(String reason) =>
          PlaylistImportAnswer.parse({'ok': false, 'reason': reason}).problem;
      expect(of('bad_link'), PlaylistImportProblem.badLink);
      expect(of('mix'), PlaylistImportProblem.mix);
      expect(of('private'), PlaylistImportProblem.privateList);
      expect(of('unavailable'), PlaylistImportProblem.unavailable);
    });

    test('an answer in the wrong shape is a FormatException', () {
      void bad(Object? body) => expect(
            () => PlaylistImportAnswer.parse(body),
            throwsA(isA<FormatException>()),
          );
      bad(null);
      bad('x');
      bad({'ok': 'yes'});
      bad({'ok': true});
      bad({'ok': true, 'songs': 'nope'});
      bad({'ok': false, 'reason': 'something new'});
      bad({'ok': false});
    });
  });
}
