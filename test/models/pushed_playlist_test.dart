import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/content_pack.dart';
import 'package:swarved/models/playlist.dart';
import 'package:swarved/models/pushed_playlist.dart';

void main() {
  group('PushedPlaylist.tryParse', () {
    test('reads a name, cover, note and YouTube songs', () {
      final pushed = PushedPlaylist.tryParse({
        'name': '  Slow   dances ',
        'cover': '0123456789abcdef.jpg',
        'note': ' for rainy days ',
        'songs': [
          {
            'id': 'yt:dQw4w9WgXcQ',
            'title': 'How Bad',
            'artist': 'Asal',
            'durationSeconds': 215,
          },
        ],
      })!;

      expect(pushed.playlist.name, 'Slow dances');
      expect(pushed.playlist.kind, PlaylistKind.pushed);
      expect(pushed.playlist.isEditable, isFalse);
      expect(pushed.coverFile, '0123456789abcdef.jpg');
      expect(pushed.note, 'for rainy days');
      final item = pushed.playlist.items.single;
      expect(item.key, 'yt:dQw4w9WgXcQ');
      expect(item.duration, const Duration(seconds: 215));
      expect(
          item.artworkUrl, 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg');
    });

    test('a nameless playlist, or one that is not an object, is skipped', () {
      expect(PushedPlaylist.tryParse({'name': '  '}), isNull);
      expect(PushedPlaylist.tryParse({'songs': []}), isNull);
      expect(PushedPlaylist.tryParse('nope'), isNull);
    });

    test('songs without a valid YouTube link are skipped, repeats kept once',
        () {
      final pushed = PushedPlaylist.tryParse({
        'name': 'Mix',
        'songs': [
          {'title': 'No link'},
          {'id': 'yt:'},
          {'id': 'abc'},
          {'id': 'yt:aaaaaaaaaaa'},
          {'id': 'yt:aaaaaaaaaaa'},
          'junk',
        ],
      })!;
      expect(pushed.playlist.items.map((i) => i.key), ['yt:aaaaaaaaaaa']);
    });

    test('a bad cover name is ignored', () {
      final pushed =
          PushedPlaylist.tryParse({'name': 'Mix', 'cover': '../x.jpg'})!;
      expect(pushed.coverFile, isNull);
    });

    test('the same name always gives the same id, whatever the case', () {
      expect(PushedPlaylist.idFor('Slow dances'),
          PushedPlaylist.idFor('slow  DANCES!'));
      expect(PushedPlaylist.idFor('A'), isNot(PushedPlaylist.idFor('B')));
    });
  });

  test('ContentPack keeps his playlists in order, once each', () {
    final pack = ContentPack.parse('''{"playlists":[
      {"name":"B","songs":[]},{"name":"A"},{"name":"b"},{"songs":[]},7]}''');
    expect(pack.playlists.map((p) => p.playlist.name), ['B', 'A']);
  });

  test('no playlists in the content means none', () {
    expect(ContentPack.parse('{}').playlists, isEmpty);
    expect(ContentPack.parse('{"playlists":"x"}').playlists, isEmpty);
  });
}
