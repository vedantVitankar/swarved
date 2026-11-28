import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:swarved/models/playlist_import.dart';
import 'package:swarved/services/secure_token_store.dart';
import 'package:swarved/services/server_api.dart';
import 'package:swarved/services/server_config.dart';

class _FakeTokenStore implements TokenStore {
  _FakeTokenStore(this.token);

  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String value) async => token = value;

  @override
  Future<void> deleteToken() async => token = null;
}

http.Response _json(String body, [int status = 200]) => http.Response(
      body,
      status,
      headers: {'content-type': 'application/json'},
    );

ServerApi _api(MockClientHandler handler, {String? token = 'secret'}) {
  return ServerApi(
    config: const ServerConfig(),
    tokenStore: _FakeTokenStore(token),
    client: MockClient(handler),
  );
}

const _link = 'https://www.youtube.com/playlist?list=PLabcdefghijklmnop';

void main() {
  group('ServerApi.importPlaylist', () {
    test('sends the token and the link, and reads the playlist', () async {
      late http.Request seen;
      final api = _api((request) async {
        seen = request;
        return _json('''
          {"ok": true, "title": "Mine", "skipped": 0, "truncated": false,
           "songs": [{"id": "sJV8kbT1MEU", "title": "Kesariya",
                      "artist": "Arijit Singh", "durationSeconds": 268,
                      "thumbnailUrl": "https://example.com/a.jpg"}]}''');
      });

      final result = await api.importPlaylist(_link);

      expect(seen.method, 'GET');
      expect(seen.headers['X-Token'], 'secret');
      expect(seen.url.path, '/api/yt-playlist');
      expect(seen.url.queryParameters['url'], _link);
      final answer = (result as ServerOk<PlaylistImportAnswer>).value;
      expect(answer.playlist!.title, 'Mine');
      expect(answer.playlist!.songs.single.id, 'sJV8kbT1MEU');
    });

    test('a link the server refuses comes back as its reason', () async {
      final api = _api(
        (_) async => _json('{"ok": false, "reason": "mix"}'),
      );
      final result = await api.importPlaylist(_link);
      final answer = (result as ServerOk<PlaylistImportAnswer>).value;
      expect(answer.problem, PlaylistImportProblem.mix);
    });

    test('no token is unauthorized, and nothing is sent', () async {
      var sent = false;
      final api = _api((_) async {
        sent = true;
        return _json('{}');
      }, token: null);
      expect(
        await api.importPlaylist(_link),
        isA<ServerUnauthorized<PlaylistImportAnswer>>(),
      );
      expect(sent, isFalse);
    });

    test('a wrong token is unauthorized', () async {
      final api = _api((_) async => _json('{}', 401));
      expect(
        await api.importPlaylist(_link),
        isA<ServerUnauthorized<PlaylistImportAnswer>>(),
      );
    });

    test('a server error or timeout is unavailable', () async {
      final api = _api((_) async => _json('{}', 504));
      expect(
        await api.importPlaylist(_link),
        isA<ServerUnavailable<PlaylistImportAnswer>>(),
      );
    });

    test('an answer in the wrong shape is unexpected', () async {
      final api = _api((_) async => _json('{"ok": "maybe"}'));
      expect(
        await api.importPlaylist(_link),
        isA<ServerUnexpected<PlaylistImportAnswer>>(),
      );
    });
  });
}
