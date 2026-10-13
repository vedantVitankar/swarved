import '../utils/song_match.dart';
import '../utils/track_key.dart';
import 'playlist.dart';
import 'playlist_item.dart';
import 'song_of_the_day.dart';

/// A playlist he made for her in the admin site: its songs (YouTube songs,
/// which play from the server), a cover photo when he chose one, and a
/// note from him. Read only for her; she can save a copy to her library.
class PushedPlaylist {
  PushedPlaylist({required this.playlist, this.coverFile, this.note});

  /// The playlist as the app draws it, of kind [PlaylistKind.pushed].
  final Playlist playlist;

  /// The uploaded photo's name, see MediaCache, or null.
  final String? coverFile;
  final String? note;

  /// Why ids come from the name: the content file gives playlists no id,
  /// and the same name should stay the same playlist across publishes.
  static String idFor(String name) =>
      'pushed_${stableHash(normalizeForMatch(name))}';

  static final DateTime _epoch = DateTime.utc(1970);
  static final RegExp _photoName = RegExp(r'^[a-f0-9]{16}\.(jpg|png|webp)$');

  /// Null when [json] has no name. A song with no valid YouTube link is
  /// skipped (the app can only play his songs from YouTube), and a song twice
  /// is kept once.
  static PushedPlaylist? tryParse(Object? json) {
    if (json is! Map) return null;
    final rawName = json['name'];
    if (rawName is! String) return null;
    final name = Playlist.cleanName(rawName);
    if (name.isEmpty) return null;

    final seen = <String>{};
    final items = <PlaylistItem>[];
    final songs = json['songs'];
    if (songs is List) {
      for (final entry in songs) {
        final item = _item(entry);
        if (item != null && seen.add(item.key)) items.add(item);
      }
    }

    final cover = json['cover'];
    final note = json['note'];
    final trimmedNote = note is String ? note.trim() : '';
    return PushedPlaylist(
      playlist: Playlist(
        id: idFor(name),
        name: name,
        kind: PlaylistKind.pushed,
        items: items,
        createdAt: _epoch,
        updatedAt: _epoch,
      ),
      coverFile: cover is String && _photoName.hasMatch(cover) ? cover : null,
      note: trimmedNote.isEmpty ? null : trimmedNote,
    );
  }

  static PlaylistItem? _item(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    if (id is! String) return null;
    final key = id.trim();
    if (!key.startsWith(youtubeKeyPrefix) ||
        key.length <= youtubeKeyPrefix.length) {
      return null;
    }
    String text(String name) {
      final value = json[name];
      return value is String ? value.trim() : '';
    }

    final seconds = json['durationSeconds'];
    return PlaylistItem(
      key: key,
      title: text('title'),
      artist: text('artist'),
      duration: seconds is num && seconds > 0
          ? Duration(seconds: seconds.round())
          : Duration.zero,
      artworkUrl: SongOfTheDay.thumbnailFor(
        key.substring(youtubeKeyPrefix.length),
      ),
      addedAt: _epoch,
    );
  }
}
