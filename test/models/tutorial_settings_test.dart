import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/tutorial_settings.dart';
import 'package:swarved/models/welcome_settings.dart';

void main() {
  group('TutorialSettings.parse', () {
    test('nothing written means the default song and captions', () {
      for (final json in <Object?>[null, 'text', 42, [], {}]) {
        final settings = TutorialSettings.parse(json);

        expect(settings.asset, TutorialSettings.defaultAsset);
        expect(settings.title, isNull);
        expect(settings.artist, isNull);
        expect(settings.label, isNull);
        expect(settings.note, isNull);
        expect(settings.captions, isEmpty);
        expect(settings.alwaysAskForFolder, isFalse);
      }
    });

    test('alwaysAskForFolder is on only for a real true', () {
      expect(
        TutorialSettings.parse({'alwaysAskForFolder': true})
            .alwaysAskForFolder,
        isTrue,
      );
      for (final value in <Object?>[false, 'true', 1, null]) {
        expect(
          TutorialSettings.parse({'alwaysAskForFolder': value})
              .alwaysAskForFolder,
          isFalse,
        );
      }
    });

    test('reads the song', () {
      final settings = TutorialSettings.parse({
        'song': {
          'asset': 'assets/welcome/how_bad.mp3',
          'title': ' How Bad ',
          'artist': 'Asal',
          'label': 'For you, Sweetheart',
          'note': 'Our first song here.',
        },
      });

      expect(settings.asset, 'assets/welcome/how_bad.mp3');
      expect(settings.title, 'How Bad');
      expect(settings.artist, 'Asal');
      expect(settings.label, 'For you, Sweetheart');
      expect(settings.note, 'Our first song here.');
    });

    test('a blank or wrongly typed asset falls back to the default', () {
      for (final asset in <Object?>['', '   ', 7, null]) {
        final settings = TutorialSettings.parse({
          'song': {'asset': asset},
        });

        expect(settings.asset, TutorialSettings.defaultAsset);
      }
    });

    test('a song that is not an object is ignored', () {
      final settings = TutorialSettings.parse({'song': 'nope'});

      expect(settings.asset, TutorialSettings.defaultAsset);
      expect(settings.title, isNull);
    });

    test('reads captions, dropping blank and wrongly typed ones', () {
      final settings = TutorialSettings.parse({
        'captions': {
          'play': ' Go on. ',
          'chips': '',
          'us': 5,
          'folders': 'Here.',
        },
      });

      expect(settings.captions, {'play': 'Go on.', 'folders': 'Here.'});
    });

    test('captions that are not an object are empty', () {
      expect(TutorialSettings.parse({'captions': 'x'}).captions, isEmpty);
    });
  });

  group('WelcomeSettings tutorial', () {
    test('is read from the "tutorial" block', () {
      final settings = WelcomeSettings.parse({
        'tutorial': {
          'song': {'title': 'How Bad'},
        },
      });

      expect(settings.tutorial.title, 'How Bad');
    });

    test('is the default when the block is missing', () {
      final settings = WelcomeSettings.parse({'line': 'Hi.'});

      expect(settings.tutorial.asset, TutorialSettings.defaultAsset);
    });
  });
}
