import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:swarved/models/playlist.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/services/playlist_reporter.dart';
import 'package:swarved/services/playlist_service.dart';
import 'package:swarved/services/playlist_store.dart';
import 'package:swarved/services/secure_token_store.dart';
import 'package:swarved/services/server_config.dart';

class _Store implements PlaylistStore {
  List<Playlist> kept = [];
  @override
  Future<List<Playlist>> read() async => List.of(kept);
  @override
  Future<void> write(List<Playlist> playlists) async => kept = playlists;
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

Track _song(String id) => Track.youtube(
      videoId: id,
      title: 'Song $id',
      artist: 'Artist',
      duration: const Duration(seconds: 100),
    );

void main() {
  late PlaylistService service;
  late List<http.Request> sent;
  late int status;

  setUp(() async {
    service = PlaylistService(store: _Store());
    await service.load();
    sent = [];
    status = 200;
  });

  tearDown(() => service.dispose());

  PlaylistReporter reporter({String? token = 'secret'}) {
    return PlaylistReporter(
      config: const ServerConfig(),
      tokenStore: _Tokens(token),
      playlists: service,
      client: MockClient((request) async {
        sent.add(request);
        return http.Response('{}', status);
      }),
      delay: const Duration(milliseconds: 20),
      retryAfter: const Duration(milliseconds: 60),
    );
  }

  test('sends her playlists with the token to the report address', () async {
    service.toggleLiked(_song('aaaaaaaaaaa'));
    final ok = await reporter().reportNow();

    expect(ok, isTrue);
    expect(sent.single.url, const ServerConfig().playlistsReportUri);
    expect(sent.single.headers['X-Token'], 'secret');
    final playlists = jsonDecode(sent.single.body)['playlists'] as List;
    expect(playlists.single['id'], 'liked');
    expect((playlists.single['items'] as List).single['key'], 'yt:aaaaaaaaaaa');
  });

  test('his pushed playlists are never sent', () {
    final r = reporter();
    final listed = (jsonDecode(r.body())['playlists'] as List)
        .map((p) => p['kind'])
        .toList();
    expect(listed, isNot(contains('pushed')));
  });

  test('an unchanged list is not sent twice', () async {
    final r = reporter();
    service.toggleLiked(_song('aaaaaaaaaaa'));
    await r.reportNow();
    await r.reportNow();
    expect(sent, hasLength(1));

    service.toggleLiked(_song('bbbbbbbbbbb'));
    await r.reportNow();
    expect(sent, hasLength(2));
  });

  test('without a token nothing is sent, and a poke sends afterwards',
      () async {
    final tokens = _Tokens(null);
    final r = PlaylistReporter(
      config: const ServerConfig(),
      tokenStore: tokens,
      playlists: service,
      client: MockClient((request) async {
        sent.add(request);
        return http.Response('{}', 200);
      }),
      delay: const Duration(milliseconds: 20),
    );
    expect(await r.reportNow(), isFalse);
    expect(sent, isEmpty);

    tokens.token = 'now';
    r.poke();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(sent, hasLength(1));
    r.dispose();
  });

  test('a refused token is not retried by itself, a server error is',
      () async {
    final r = reporter();
    status = 401;
    expect(await r.reportNow(), isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(sent, hasLength(1));

    status = 500;
    expect(await r.reportNow(), isFalse);
    status = 200;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(sent.length, greaterThan(2));
    r.dispose();
  });

  test('a change is sent a moment later, once, however many there are',
      () async {
    final r = reporter()..start();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    sent.clear();

    service.toggleLiked(_song('aaaaaaaaaaa'));
    service.toggleLiked(_song('bbbbbbbbbbb'));
    service.create('Slow dances');
    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(sent, hasLength(1));
    expect(jsonDecode(sent.single.body)['playlists'], hasLength(2));
    r.dispose();
  });

  test('a network failure never throws', () async {
    final r = PlaylistReporter(
      config: const ServerConfig(),
      tokenStore: _Tokens('secret'),
      playlists: service,
      client: MockClient((request) async => throw Exception('offline')),
      retryAfter: const Duration(minutes: 5),
    );
    expect(await r.reportNow(), isFalse);
    r.dispose();
  });
}
