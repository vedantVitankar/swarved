import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/content_pack.dart';
import 'package:swarved/models/panel_settings.dart';

String content(Map<String, Object?> sections) =>
    jsonEncode({'schema': 1, ...sections});

void main() {
  group('the right-hand section in the content', () {
    test('without it, the section has its plain defaults', () {
      final pack = ContentPack.parse(content({}));
      expect(pack.panel.shown.length, 4);
      expect(pack.together.meetingDate, isNull);
      expect(pack.letters, isEmpty);
    });

    test('the panel, the countdown and the letters are read', () {
      final pack = ContentPack.parse(content({
        'panel': {'pinned': 'Hi', 'hideLetters': true},
        'together': {'meetingDate': '2026-12-25', 'meetingLabel': 'Soon'},
        'letters': [
          {'id': 'abc12345', 'when': 'you miss me', 'body': 'Here.'},
        ],
      }));
      expect(pack.panel.pinned, 'Hi');
      expect(pack.panel.hidden, {PanelBlock.letters});
      expect(pack.together.meetingLabel, 'Soon');
      expect(pack.letters.single.heading, 'Open when you miss me');
    });

    test('a bad letter is skipped and the others stay', () {
      final pack = ContentPack.parse(content({
        'letters': [
          {'id': 'x', 'when': 'bad id', 'body': 'x'},
          {'id': 'abc12345', 'when': 'good', 'body': 'x'},
          'nonsense',
        ],
      }));
      expect(pack.letters.map((l) => l.id), ['abc12345']);
    });

    test('two letters with one id keep the first', () {
      final pack = ContentPack.parse(content({
        'letters': [
          {'id': 'abc12345', 'when': 'first', 'body': 'x'},
          {'id': 'abc12345', 'when': 'second', 'body': 'x'},
        ],
      }));
      expect(pack.letters.single.when, 'first');
    });

    test('letters that are not a list are none', () {
      expect(ContentPack.parse(content({'letters': {'a': 1}})).letters, isEmpty);
    });

    test('the files in letters and the pinned photo are kept, not cleaned away',
        () {
      final pack = ContentPack.parse(content({
        'panel': {'pinnedPhoto': 'aaaaaaaaaaaaaaaa.jpg'},
        'letters': [
          {
            'id': 'abc12345',
            'when': 'x',
            'photo': 'bbbbbbbbbbbbbbbb.png',
            'voice': 'cccccccccccccccc.mp3',
          },
        ],
        'memories': [
          {
            'date': '2026-01-01',
            'caption': 'x',
            'image': 'dddddddddddddddd.jpg',
            'song': {'id': 'yt:dQw4w9WgXcQ', 'title': 'x'},
          },
        ],
      }));
      expect(pack.mediaFiles, containsAll([
        'aaaaaaaaaaaaaaaa.jpg',
        'bbbbbbbbbbbbbbbb.png',
        'cccccccccccccccc.mp3',
        'dddddddddddddddd.jpg',
      ]));
    });
  });
}
