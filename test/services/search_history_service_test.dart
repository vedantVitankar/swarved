import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/playlist.dart';
import 'package:swarved/models/search_history_entry.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/services/playlist_service.dart';
import 'package:swarved/services/playlist_store.dart';
import 'package:swarved/services/search_history_service.dart';
import 'package:swarved/services/search_history_store.dart';
import 'package:swarved/services/search_history_watcher.dart';

class _HistoryStore implements SearchHistoryStore {
  _HistoryStore([List<SearchHistoryEntry> initial = const []])
      : kept = List.of(initial);

  List<SearchHistoryEntry> kept;
  int writes = 0;
  bool failRead = false;
  bool failWrite = false;

  @override
  Future<List<SearchHistoryEntry>> read() async {
    if (failRead) throw StateError('file is locked');
    return List.of(kept);
  }

  @override
  Future<void> write(List<SearchHistoryEntry> entries) async {
    if (failWrite) throw StateError('disk full');
    writes++;
    kept = entries;
  }
}

class _PlaylistStore implements PlaylistStore {
  @override
  Future<List<Playlist>> read() async => const [];

  @override
  Future<void> write(List<Playlist> playlists) async {}
}

Track _youtube(String id) => Track.youtube(
      videoId: id,
      title: 'Online $id',
      artist: 'Chan',
      duration: const Duration(seconds: 120),
    );

Track _local(String path, String title) => Track(
      filePath: path,
      title: title,
      artist: 'Her',
      album: '',
      duration: const Duration(seconds: 200),
      folder: 'Music',
    );

List<String> _ids(SearchHistoryService s) => [for (final e in s.entries) e.id];

void main() {
  group('SearchHistoryService', () {
    test('a played song is remembered at the top and saved', () async {
      final store = _HistoryStore();
      final service = SearchHistoryService(store: store);
      service.recordPlayed(_youtube('a'));
      service.recordPlayed(_youtube('b'));
      expect(_ids(service), ['yt:b', 'yt:a']);
      await service.saved;
      expect([for (final e in store.kept) e.id], ['yt:b', 'yt:a']);
    });

    test('playing a song again moves it to the top, once', () {
      final service = SearchHistoryService(store: _HistoryStore());
      service.recordPlayed(_youtube('a'));
      service.recordPlayed(_youtube('b'));
      service.recordPlayed(_youtube('a'));
      expect(_ids(service), ['yt:a', 'yt:b']);
    });

    test('only the newest 20 are kept', () {
      final service = SearchHistoryService(store: _HistoryStore());
      for (var i = 0; i < 25; i++) {
        service.recordPlayed(_youtube('id$i'));
      }
      expect(service.entries.length, 20);
      expect(service.entries.first.id, 'yt:id24');
      expect(service.entries.last.id, 'yt:id5');
    });

    test('the × takes out one song and nothing else', () async {
      final store = _HistoryStore();
      final service = SearchHistoryService(store: store);
      service.recordPlayed(_youtube('a'));
      service.recordPlayed(_youtube('b'));
      service.recordPlayed(_youtube('c'));
      service.remove('yt:b');
      expect(_ids(service), ['yt:c', 'yt:a']);
      await service.saved;
      expect([for (final e in store.kept) e.id], ['yt:c', 'yt:a']);
    });

    test('removing a song that is not there saves nothing and tells nobody',
        () async {
      final store = _HistoryStore();
      final service = SearchHistoryService(store: store);
      service.recordPlayed(_youtube('a'));
      await service.saved;
      var told = 0;
      service.addListener(() => told++);
      final writes = store.writes;
      service.remove('yt:zzz');
      await service.saved;
      expect(told, 0);
      expect(store.writes, writes);
    });

    test('clear all empties the list and the file', () async {
      final store = _HistoryStore();
      final service = SearchHistoryService(store: store);
      service.recordPlayed(_youtube('a'));
      service.recordPlayed(_youtube('b'));
      service.clearAll();
      expect(service.entries, isEmpty);
      await service.saved;
      expect(store.kept, isEmpty);
    });

    test('clear all on an empty list does nothing', () async {
      final store = _HistoryStore();
      final service = SearchHistoryService(store: store);
      var told = 0;
      service.addListener(() => told++);
      service.clearAll();
      await service.saved;
      expect(told, 0);
      expect(store.writes, 0);
    });

    test('load brings back what was saved, newest first', () async {
      final store = _HistoryStore([
        SearchHistoryEntry.fromTrack(_youtube('b'))!,
        SearchHistoryEntry.fromTrack(_youtube('a'))!,
      ]);
      final service = SearchHistoryService(store: store);
      await service.load();
      expect(_ids(service), ['yt:b', 'yt:a']);
      expect(store.writes, 0, reason: 'loading must not write the file');
    });

    test('a song played before load finishes stays on top and is not lost',
        () async {
      final store = _HistoryStore([
        SearchHistoryEntry.fromTrack(_youtube('a'))!,
        SearchHistoryEntry.fromTrack(_youtube('b'))!,
      ]);
      final service = SearchHistoryService(store: store);
      service.recordPlayed(_youtube('b'));
      await service.load();
      expect(_ids(service), ['yt:b', 'yt:a']);
    });

    test('a file that cannot be read leaves an empty list and no crash',
        () async {
      final store = _HistoryStore()..failRead = true;
      final service = SearchHistoryService(store: store);
      await service.load();
      expect(service.entries, isEmpty);
    });

    test('a failed save does not stop the list or the saves after it',
        () async {
      final store = _HistoryStore()..failWrite = true;
      final service = SearchHistoryService(store: store);
      service.recordPlayed(_youtube('a'));
      await service.saved;
      expect(_ids(service), ['yt:a']);
      store.failWrite = false;
      service.recordPlayed(_youtube('b'));
      await service.saved;
      expect([for (final e in store.kept) e.id], ['yt:b', 'yt:a']);
    });

    test('a letter recording is not remembered', () {
      final service = SearchHistoryService(store: _HistoryStore());
      service.recordPlayed(Track(
        filePath: '/x/letters/1.m4a',
        title: 'Letter',
        artist: 'Him',
        album: '',
        duration: const Duration(seconds: 30),
        folder: Track.letterRecordingFolder,
      ));
      expect(service.entries, isEmpty);
    });
  });

  group('added to a playlist', () {
    late PlaylistService playlists;
    late SearchHistoryService history;

    setUp(() async {
      playlists = PlaylistService(store: _PlaylistStore());
      await playlists.load();
      history = SearchHistoryService(store: _HistoryStore());
      SearchHistoryWatcher(history: history, playlists: playlists).start();
    });

    test('a shown song added to Liked songs is remembered', () {
      final song = _youtube('a');
      history.noteShown([song, _youtube('b')]);
      playlists.add(Playlist.likedId, song);
      expect(_ids(history), ['yt:a']);
    });

    test('adding through the popup is remembered, new playlist included', () {
      final song = _youtube('a');
      history.noteShown([song]);
      playlists.applyMembership(song, playlistIds: {}, newNames: ['Rain']);
      expect(_ids(history), ['yt:a']);
    });

    test('a local song shown in the results is remembered too', () {
      final song = _local('/m/a.mp3', 'Local');
      history.noteShown([song]);
      playlists.toggleLiked(song);
      expect(_ids(history), ['/m/a.mp3']);
    });

    test('a song that is not in the search results is not remembered', () {
      history.noteShown([_youtube('a')]);
      playlists.add(Playlist.likedId, _youtube('zzz'));
      expect(history.entries, isEmpty);
    });

    test('nothing shown means nothing is remembered', () {
      playlists.add(Playlist.likedId, _youtube('a'));
      expect(history.entries, isEmpty);
    });

    test('taking a song out of a playlist is not remembered', () {
      final song = _youtube('a');
      playlists.add(Playlist.likedId, song);
      history.noteShown([song]);
      playlists.remove(Playlist.likedId, song.id);
      expect(history.entries, isEmpty);
    });

    test('a song that was already in a playlist is not added again', () {
      final song = _youtube('a');
      playlists.add(Playlist.likedId, song);
      history.noteShown([song]);
      playlists.add(Playlist.likedId, song);
      playlists.rename(Playlist.likedId, 'x');
      expect(history.entries, isEmpty);
    });

    test('a song added to a second playlist is remembered', () {
      final song = _youtube('a');
      final rain = playlists.create('Rain')!;
      playlists.add(Playlist.likedId, song);
      history.noteShown([song]);
      playlists.add(rain.id, song);
      expect(_ids(history), ['yt:a']);
    });
  });
}
