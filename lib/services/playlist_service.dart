import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../content/words.dart';
import '../models/playlist.dart';
import '../models/playlist_item.dart';
import '../models/track.dart';
import '../utils/track_key.dart';
import 'playlist_store.dart';

/// What happened when a song was added to a playlist.
enum AddResult { added, alreadyThere, noSuchPlaylist }

/// Holds every playlist: Liked songs, the ones she makes, and later the ones
/// he sends. Every change is applied at once, tells listeners, and is saved
/// in the background, one save after another and never two at once.
///
/// Nothing here needs the network. A later sync only reads and writes the
/// playlists this holds.
class PlaylistService extends ChangeNotifier {
  PlaylistService({
    required PlaylistStore store,
    DateTime Function()? clock,
    String Function()? newId,
  })  : _store = store,
        _clock = clock ?? DateTime.now,
        _newId = newId ?? _randomId;

  /// How long a deleted playlist is remembered, so a device that was away
  /// can still be told it is gone.
  static const Duration tombstoneLife = Duration(days: 30);

  final PlaylistStore _store;
  final DateTime Function() _clock;
  final String Function() _newId;

  List<Playlist> _all = [];
  Future<void> _writing = Future.value();

  /// False when the file could not be read at all. Nothing is saved then, so
  /// a file that is merely locked is never written over.
  bool _canSave = true;
  bool _disposed = false;

  static String _randomId() {
    final random = math.Random.secure();
    final digits = List.generate(
      8,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    return 'pl_$digits';
  }

  /// Completes when everything changed so far has been saved. For tests and
  /// for a sync that wants to start from what is on disk.
  Future<void> get saved => _writing;

  /// Reads the file. Never throws. Makes sure Liked songs exists, and lets
  /// go of playlists deleted longer ago than [tombstoneLife].
  Future<void> load() async {
    var read = <Playlist>[];
    try {
      read = await _store.read();
    } catch (error) {
      debugPrint('Playlists could not be read, so none are saved: $error');
      _canSave = false;
    }

    final now = _clock();
    final seen = <String>{};
    final kept = <Playlist>[];
    for (final playlist in read) {
      if (!seen.add(playlist.id)) continue;
      final deletedAt = playlist.deletedAt;
      if (deletedAt != null && now.difference(deletedAt) > tombstoneLife) {
        continue;
      }
      kept.add(
        playlist.id == Playlist.likedId
            ? playlist.copyWith(kind: PlaylistKind.liked, undelete: true)
            : playlist,
      );
    }

    _all = kept;
    final addedLiked = !_all.any((p) => p.id == Playlist.likedId);
    if (addedLiked) {
      _all = [
        Playlist(
          id: Playlist.likedId,
          name: Words.likedSongs,
          kind: PlaylistKind.liked,
          items: const [],
          createdAt: now,
          updatedAt: now,
        ),
        ..._all,
      ];
    }
    notifyListeners();
    if (addedLiked || kept.length != read.length) _persist();
  }

  // ---- Reading ----------------------------------------------------------

  /// Every playlist that is not deleted: Liked songs first, then the rest,
  /// the newest made first.
  List<Playlist> get playlists {
    final shown = _all.where((p) => !p.isDeleted).toList();
    shown.sort((a, b) {
      if (a.isLiked != b.isLiked) return a.isLiked ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return List.unmodifiable(shown);
  }

  /// Every playlist on file, deleted ones too. For sync, which has to tell
  /// the other devices what was deleted.
  List<Playlist> get everything => List.unmodifiable(_all);

  Playlist? byId(String id) {
    for (final playlist in _all) {
      if (playlist.id == id && !playlist.isDeleted) return playlist;
    }
    return null;
  }

  /// Liked songs. Before [load] has run it is an empty one that is not kept.
  Playlist get liked {
    return _all.firstWhere(
      (p) => p.id == Playlist.likedId,
      orElse: () {
        final now = _clock();
        return Playlist(
          id: Playlist.likedId,
          name: Words.likedSongs,
          kind: PlaylistKind.liked,
          items: const [],
          createdAt: now,
          updatedAt: now,
        );
      },
    );
  }

  bool isLiked(Track track) => liked.contains(track.playlistKey);

  /// The ids of the playlists [track] is in, for the ticks in the popup.
  Set<String> playlistIdsWith(Track track) {
    final key = track.playlistKey;
    return {
      for (final playlist in playlists)
        if (playlist.contains(key)) playlist.id,
    };
  }

  // ---- Changing ---------------------------------------------------------

  /// Makes a playlist called [name], or null when the name is empty.
  Playlist? create(String name) {
    final created = _make(name);
    if (created == null) return null;
    _changed();
    return created;
  }

  /// Renames a playlist of hers. Not Liked songs, and not one he sent.
  bool rename(String id, String name) {
    final playlist = byId(id);
    final clean = Playlist.cleanName(name);
    if (playlist == null || playlist.kind != PlaylistKind.user) return false;
    if (clean.isEmpty || clean == playlist.name) return false;
    _replace(playlist.copyWith(name: clean, updatedAt: _clock()));
    _changed();
    return true;
  }

  /// Deletes a playlist of hers. It is only marked, so [restore] can bring
  /// it back. Not Liked songs, and not one he sent.
  bool delete(String id) {
    final playlist = byId(id);
    if (playlist == null || playlist.kind != PlaylistKind.user) return false;
    final now = _clock();
    _replace(playlist.copyWith(deletedAt: now, updatedAt: now));
    _changed();
    return true;
  }

  /// Undoes [delete].
  bool restore(String id) {
    final index = _all.indexWhere((p) => p.id == id);
    if (index < 0 || !_all[index].isDeleted) return false;
    _all[index] = _all[index].copyWith(undelete: true, updatedAt: _clock());
    _changed();
    return true;
  }

  /// Adds [track] to the end of a playlist. A song is in a playlist once.
  AddResult add(String playlistId, Track track) {
    final playlist = byId(playlistId);
    if (playlist == null || !playlist.isEditable) {
      return AddResult.noSuchPlaylist;
    }
    if (playlist.contains(track.playlistKey)) return AddResult.alreadyThere;
    _replace(_withSong(playlist, track));
    _changed();
    return AddResult.added;
  }

  /// The heart's long press: puts [track] in Liked songs, or takes it out
  /// when it is there. Answers whether it is liked now.
  bool toggleLiked(Track track) {
    final key = track.playlistKey;
    if (liked.contains(key)) {
      remove(Playlist.likedId, key);
      return false;
    }
    return add(Playlist.likedId, track) == AddResult.added;
  }

  /// Takes the song with [key] out of a playlist.
  bool remove(String playlistId, String key) {
    final playlist = byId(playlistId);
    if (playlist == null || !playlist.isEditable) return false;
    if (!playlist.contains(key)) return false;
    _replace(_withoutSong(playlist, key));
    _changed();
    return true;
  }

  /// Moves the song at [from] so that it ends up at [to], counting places
  /// as they are after it has been lifted out. (A list that reorders by
  /// drag reports its target one place too high when moving down, so the
  /// screen takes one off before calling this.)
  bool move(String playlistId, int from, int to) {
    final playlist = byId(playlistId);
    if (playlist == null || !playlist.isEditable) return false;
    final count = playlist.items.length;
    if (from < 0 || from >= count || to < 0 || to >= count) return false;
    if (from == to) return false;

    final items = [...playlist.items];
    items.insert(to, items.removeAt(from));
    _replace(playlist.copyWith(items: items, updatedAt: _clock()));
    _changed();
    return true;
  }

  /// What the popup does when she presses Done: makes [track] be in exactly
  /// the playlists in [playlistIds], and in a new playlist for each name in
  /// [newNames]. A playlist whose answer is the same as before is not
  /// touched, so a song she took out and put back before pressing Done keeps
  /// its place in the list. Songs that are added go to the end.
  void applyMembership(
    Track track, {
    required Set<String> playlistIds,
    List<String> newNames = const [],
  }) {
    final key = track.playlistKey;
    var changed = false;

    for (final playlist in playlists) {
      if (!playlist.isEditable) continue;
      final wanted = playlistIds.contains(playlist.id);
      if (wanted == playlist.contains(key)) continue;
      _replace(
        wanted ? _withSong(playlist, track) : _withoutSong(playlist, key),
      );
      changed = true;
    }

    for (final name in newNames) {
      final created = _make(name);
      if (created == null) continue;
      _replace(_withSong(created, track));
      changed = true;
    }

    if (changed) _changed();
  }

  // ---- Inside ------------------------------------------------------------

  Playlist? _make(String name) {
    final clean = Playlist.cleanName(name);
    if (clean.isEmpty) return null;
    final now = _clock();
    final playlist = Playlist(
      id: _newId(),
      name: clean,
      kind: PlaylistKind.user,
      items: const [],
      createdAt: now,
      updatedAt: now,
    );
    _all = [..._all, playlist];
    return playlist;
  }

  Playlist _withSong(Playlist playlist, Track track) {
    final now = _clock();
    return playlist.copyWith(
      items: [...playlist.items, PlaylistItem.fromTrack(track, addedAt: now)],
      updatedAt: now,
    );
  }

  Playlist _withoutSong(Playlist playlist, String key) {
    return playlist.copyWith(
      items: [
        for (final item in playlist.items)
          if (item.key != key) item,
      ],
      updatedAt: _clock(),
    );
  }

  void _replace(Playlist updated) {
    _all = [
      for (final playlist in _all)
        if (playlist.id == updated.id) updated else playlist,
    ];
  }

  void _changed() {
    if (!_disposed) notifyListeners();
    _persist();
  }

  /// Saves what is held when its turn comes, so a quick run of changes is
  /// saved in order and the last save is always the newest state.
  void _persist() {
    if (!_canSave) return;
    _writing = _writing.then((_) => _store.write(List.of(_all))).catchError(
      (Object error) {
        debugPrint('Playlists could not be saved: $error');
      },
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
