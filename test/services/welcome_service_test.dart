import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/content_pack.dart';
import 'package:swarved/services/welcome_service.dart';

void main() {
  group('WelcomeService', () {
    test('starts with the default welcome, before anything is loaded', () {
      final service = WelcomeService(loader: () async => '{}');

      expect(service.settings.line, isNull);
      expect(service.settings.signature, isNull);
      expect(service.settings.story, isEmpty);
      expect(service.settings.notes, isEmpty);
    });

    test('reads the line, signature, story and notes', () async {
      final service = WelcomeService(
        loader: () async => '{"line": "Hi.", "signature": "Ved", '
            '"story": ["One.", "Two."], "notes": ["A note."]}',
      );

      await service.load();

      expect(service.settings.line, 'Hi.');
      expect(service.settings.signature, 'Ved');
      expect(service.settings.story, ['One.', 'Two.']);
      expect(service.settings.notes.single.note, 'A note.');
    });

    test('a broken file leaves the defaults and does not throw', () async {
      final service = WelcomeService(loader: () async => 'not json');

      await service.load();

      expect(service.settings.line, isNull);
      expect(service.settings.story, isEmpty);
    });

    test('a file that is not an object leaves the defaults', () async {
      final service = WelcomeService(loader: () async => '[1, 2, 3]');

      await service.load();

      expect(service.settings.line, isNull);
      expect(service.settings.notes, isEmpty);
    });

    test('a loader that fails leaves the defaults and does not throw',
        () async {
      final service = WelcomeService(loader: () async => throw Exception('no'));

      await service.load();

      expect(service.settings.line, isNull);
    });

    test('loading again after a failure picks up a good file', () async {
      var text = 'not json';
      final service = WelcomeService(loader: () async => text);

      await service.load();
      expect(service.settings.line, isNull);

      text = '{"line": "Back again."}';
      await service.load();
      expect(service.settings.line, 'Back again.');
    });
  });

  group('The two bundled files', () {
    // flutter test runs from the project folder, so the real files can be
    // read straight from disk.
    Map<String, dynamic> readJson(String path) =>
        jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

    test('welcome.json is valid and says something in every part', () async {
      final text = File('assets/welcome/welcome.json').readAsStringSync();
      final service = WelcomeService(loader: () async => text);

      await service.load();

      expect(service.settings.line, isNotNull);
      expect(service.settings.signature, isNotNull);
      expect(service.settings.story, isNotEmpty);
      expect(service.settings.notes, isNotEmpty);
    });

    test('content.json no longer carries a welcome block', () {
      // The welcome has its own file; the content pushed later must have
      // nothing of it to overwrite.
      expect(readJson('assets/content/content.json'),
          isNot(contains('welcome')));
    });

    test('content.json still loads without it', () {
      final text = File('assets/content/content.json').readAsStringSync();

      expect(() => ContentPack.parse(text), returnsNormally);
    });

    test('both files are listed as assets in pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();

      expect(pubspec, contains('- assets/welcome/'));
      expect(pubspec, contains('- assets/content/'));
    });
  });
}
