import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:swarved/services/secure_token_store.dart';
import 'package:swarved/services/server_config.dart';
import 'package:swarved/services/voice_progress_reporter.dart';
import 'package:swarved/utils/app_profile.dart';

class _Tokens implements TokenStore {
  _Tokens(this.token);
  String? token;
  @override
  Future<String?> readToken() async => token;
  @override
  Future<void> writeToken(String value) async => token = value;
  @override
  Future<void> deleteToken() async => token = null;
}

void main() {
  late List<http.Request> asked;

  setUp(() => asked = []);

  VoiceProgressReporter reporter({
    String? token = 'secret',
    ServerConfig config = const ServerConfig(),
    int status = 200,
    bool offline = false,
  }) {
    return VoiceProgressReporter(
      config: config,
      tokenStore: _Tokens(token),
      client: MockClient((request) async {
        asked.add(request);
        if (offline) throw Exception('offline');
        return http.Response('{}', status);
      }),
    );
  }

  test('sends the last one and everything played, with the token', () async {
    final ok = await reporter().report('a.mp3', ['a.mp3', 'b.mp3']);

    expect(ok, isTrue);
    expect(asked.single.method, 'POST');
    expect(asked.single.url, const ServerConfig().voicesPlayedUri);
    expect(asked.single.headers['X-Token'], 'secret');
    expect(jsonDecode(asked.single.body), {
      'last': 'a.mp3',
      'played': ['a.mp3', 'b.mp3'],
    });
  });

  test('a reset is reported as nothing played', () async {
    await reporter().report(null, const []);
    expect(jsonDecode(asked.single.body), {'last': null, 'played': []});
  });

  test('a test build names the test profile', () async {
    await reporter(config: const ServerConfig(profile: AppProfile.test))
        .report(null, const []);
    expect(asked.single.url.queryParameters, {'profile': 'test'});
  });

  test('without a token nothing is sent', () async {
    expect(await reporter(token: null).report(null, const []), isFalse);
    expect(asked, isEmpty);
  });

  test('a refusal or no connection gives false and never throws', () async {
    expect(await reporter(status: 500).report(null, const []), isFalse);
    expect(await reporter(offline: true).report(null, const []), isFalse);
  });
}
