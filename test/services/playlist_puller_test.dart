import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:swarved/models/playlist.dart';
import 'package:swarved/services/playlist_puller.dart';
import 'package:swarved/services/playlist_service.dart';
import 'package:swarved/services/playlist_store.dart';
import 'package:swarved/services/secure_token_store.dart';
import 'package:swarved/services/server_config.dart';
import 'package:swarved/utils/app_profile.dart';

class _Store implements PlaylistStore {
  @override
  Future<List<Playlist>> read() async => [];
  @override
  Future<void> write(List<Playlist> playlists) async {}
}

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

Map<String, dynamic> _remote(String id, String name) => {
      'id': id,
      'name': name,
      'kind': 'user',
      'createdAt': '2026-10-01T10:00:00.000Z',
      'updatedAt': '2026-10-02T10:00:00.000Z',
      'items': [
        {
          'key': 'yt:dQw4w9WgXcQ',
          'title': 'How Bad',
          'artist': 'Asal',
          'durationSeconds': 215,
          'addedAt': '2026-10-02T10:00:00.000Z',
        },
      ],
    };

void main() {
  late PlaylistService service;
  late List<http.Request> asked;

  setUp(() async {
    service = PlaylistService(store: _Store());
    await service.load();
    asked = [];
  });

  tearDown(() => service.dispose());

  PlaylistPuller puller({
    String? token = 'secret',
    ServerConfig config = const ServerConfig(),
    Future<http.Response> Function(http.Request)? answer,
  }) {
    return PlaylistPuller(
      config: config,
      tokenStore: _Tokens(token),
      playlists: service,
      client: MockClient((request) async {
        asked.add(request);
        if (answer != null) return await answer(request);
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'playlists': [_remote('pl_1', 'स्वर नीमा')],
          })),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      every: const Duration(days: 1),
    );
  }

  test('reads her playlists with the token and merges them in', () async {
    final ok = await puller().pullNow();

    expect(ok, isTrue);
    expect(asked.single.method, 'GET');
    expect(asked.single.url, const ServerConfig().playlistsUri);
    expect(asked.single.headers['X-Token'], 'secret');
    expect(service.byId('pl_1'), isNotNull);
  });

  test('names in any script arrive whole', () async {
    await puller().pullNow();
    expect(service.byId('pl_1')!.name, 'स्वर नीमा');
  });

  test('a test build asks for the test profile', () async {
    await puller(config: const ServerConfig(profile: AppProfile.test))
        .pullNow();
    expect(asked.single.url.queryParameters, {'profile': 'test'});
  });

  test('without a token nothing is asked', () async {
    expect(await puller(token: null).pullNow(), isFalse);
    expect(asked, isEmpty);
  });

  test('a refused or broken answer changes nothing and never throws', () async {
    expect(
      await puller(answer: (_) async => http.Response('no', 401)).pullNow(),
      isFalse,
    );
    expect(
      await puller(answer: (_) async => http.Response('not json', 200))
          .pullNow(),
      isFalse,
    );
    expect(
      await puller(answer: (_) async => http.Response('{"x": 1}', 200))
          .pullNow(),
      isFalse,
    );
    expect(
      await puller(answer: (_) async => throw Exception('offline')).pullNow(),
      isFalse,
    );
    expect(service.byId('pl_1'), isNull);
  });

  test('one bad playlist does not spoil the others', () async {
    await puller(
      answer: (_) async => http.Response(
        jsonEncode({
          'playlists': [
            'nonsense',
            {'id': 5},
            _remote('pl_2', 'Fine'),
          ],
        }),
        200,
      ),
    ).pullNow();
    expect(service.byId('pl_2')!.name, 'Fine');
  });
}
