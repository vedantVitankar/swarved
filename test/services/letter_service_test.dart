import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swarved/services/letter_service.dart';
import 'package:swarved/services/letters_opened_reporter.dart';
import 'package:swarved/services/secure_token_store.dart';
import 'package:swarved/services/server_config.dart';
import 'package:swarved/utils/app_profile.dart';

class _Token implements TokenStore {
  _Token(this.token);
  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String value) async => token = value;

  @override
  Future<void> deleteToken() async => token = null;
}

void main() {
  late List<http.Request> requests;
  late bool serverWorks;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    requests = [];
    serverWorks = true;
  });

  LettersOpenedReporter reporter({String? token = 'secret', String profile = AppProfile.swarnima}) {
    return LettersOpenedReporter(
      config: ServerConfig(profile: profile),
      tokenStore: _Token(token),
      client: MockClient((request) async {
        requests.add(request);
        if (!serverWorks) throw http.ClientException('down');
        return http.Response('{"ok":true}', 200);
      }),
    );
  }

  LetterService service({DateTime? now}) => LetterService(
        reporter: reporter(),
        clock: () => now ?? DateTime.utc(2026, 10, 25, 12),
      );

  Map<String, dynamic> openedIn(http.Request request) =>
      (jsonDecode(request.body) as Map)['opened'] as Map<String, dynamic>;

  group('LettersOpenedReporter', () {
    test('sends the letters and when, with the token', () async {
      final ok = await reporter().report({
        'abc12345': DateTime.utc(2026, 10, 25, 12),
      });

      expect(ok, isTrue);
      expect(requests.single.method, 'POST');
      expect(requests.single.url.path, '/api/letters/opened');
      expect(requests.single.headers['X-Token'], 'secret');
      expect(openedIn(requests.single), {'abc12345': '2026-10-25T12:00:00.000Z'});
    });

    test('names the profile for the test copy', () async {
      await reporter(profile: AppProfile.test).report({});
      expect(requests.single.url.queryParameters['profile'], 'test');
    });

    test('without a token it asks nothing', () async {
      expect(await reporter(token: null).report({}), isFalse);
      expect(requests, isEmpty);
    });

    test('a failure is false, never an exception', () async {
      serverWorks = false;
      expect(await reporter().report({}), isFalse);
    });
  });

  group('LetterService', () {
    test('nothing is opened to begin with', () {
      expect(service().isOpened('abc12345'), isFalse);
    });

    test('opening a letter notes it, saves it and tells the server', () async {
      final letters = service();
      final heard = <bool>[];
      letters.addListener(() => heard.add(letters.isOpened('abc12345')));

      await letters.markOpened('abc12345');
      await pumpEventQueue();

      expect(letters.isOpened('abc12345'), isTrue);
      expect(heard, [true]);
      expect(openedIn(requests.single), {'abc12345': '2026-10-25T12:00:00.000Z'});
    });

    test('a letter is only noted the first time', () async {
      final letters = service();
      await letters.markOpened('abc12345');
      await pumpEventQueue();
      await letters.markOpened('abc12345');
      await pumpEventQueue();
      expect(requests, hasLength(1));
    });

    test('each report carries every letter opened so far', () async {
      final letters = service();
      await letters.markOpened('abc12345');
      await letters.markOpened('def67890');
      await pumpEventQueue();
      expect(openedIn(requests.last).keys, {'abc12345', 'def67890'});
    });

    test('what was opened is still opened after a restart', () async {
      await service().markOpened('abc12345');
      await pumpEventQueue();
      requests.clear();

      final again = service();
      expect(again.isOpened('abc12345'), isFalse);
      await again.load();
      await pumpEventQueue();

      expect(again.isOpened('abc12345'), isTrue);
      // A report that was missed is made up at start.
      expect(openedIn(requests.single).keys, {'abc12345'});
    });

    test('with nothing saved, start tells the server nothing', () async {
      await service().load();
      await pumpEventQueue();
      expect(requests, isEmpty);
    });

    test('a damaged save is no letters, not a crash', () async {
      for (final bad in ['not json', '[1]', '{"abc12345": 5}', '{"abc12345": "later"}']) {
        SharedPreferences.setMockInitialValues({'letters_opened': bad});
        final letters = service();
        await letters.load();
        expect(letters.isOpened('abc12345'), isFalse, reason: bad);
      }
    });

    test('a server that is down does not stop her opening a letter', () async {
      serverWorks = false;
      final letters = service();
      await letters.markOpened('abc12345');
      await pumpEventQueue();
      expect(letters.isOpened('abc12345'), isTrue);
    });
  });
}
