import 'playlist_item.dart';

/// Whose a playlist is. Liked songs is the one every listener has, [user]
/// playlists are made in the app, and [pushed] ones arrive from him and are
/// read only.
enum PlaylistKind { liked, user, pushed }

/// A named, ordered list of songs, local and YouTube mixed freely.
///
/// Immutable: every change makes a new one. A deleted playlist is not
/// dropped but marked with [deletedAt], so deleting can be undone, and so
/// that a later sync can tell another device the playlist is gone rather
/// than missing.
class Playlist {
  Playlist({
    required this.id,
    required this.name,
    required this.kind,
    required List<PlaylistItem> items,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  }) : items = List.unmodifiable(items);

  /// The id of Liked songs. There is only ever one.
  static const String likedId = 'liked';

  static const int maxNameLength = 60;

  final String id;
  final String name;
  final PlaylistKind kind;
  final List<PlaylistItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isLiked => kind == PlaylistKind.liked;
  bool get isDeleted => deletedAt != null;

  /// Songs can be added, removed and moved, and a user playlist renamed.
  bool get isEditable => kind != PlaylistKind.pushed;

  bool contains(String key) => items.any((item) => item.key == key);

  Duration get totalDuration =>
      items.fold(Duration.zero, (sum, item) => sum + item.duration);

  Playlist copyWith({
    String? name,
    PlaylistKind? kind,
    List<PlaylistItem>? items,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool undelete = false,
  }) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      items: items ?? this.items,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: undelete ? null : (deletedAt ?? this.deletedAt),
    );
  }

  /// A name as it is kept: trimmed, runs of spaces made one, and no longer
  /// than [maxNameLength]. Empty when nothing is left, which is not a name.
  static String cleanName(String raw) {
    final single = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    final runes = single.runes;
    if (runes.length <= maxNameLength) return single;
    return String.fromCharCodes(runes.take(maxNameLength)).trim();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        if (deletedAt != null)
          'deletedAt': deletedAt!.toUtc().toIso8601String(),
        'items': [for (final item in items) item.toJson()],
      };

  /// Null when [json] has no id or name. A song twice in one playlist is
  /// kept once, the first time, and a song with a bad key is skipped.
  static Playlist? tryParse(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final name = json['name'];
    if (id is! String || id.isEmpty) return null;
    if (name is! String) return null;

    final seen = <String>{};
    final items = <PlaylistItem>[];
    final raw = json['items'];
    if (raw is List) {
      for (final entry in raw) {
        final item = PlaylistItem.tryParse(entry);
        if (item != null && seen.add(item.key)) items.add(item);
      }
    }

    final created = _time(json['createdAt']) ?? _epoch;
    final deleted = _time(json['deletedAt']);
    return Playlist(
      id: id,
      name: name,
      kind: _kind(json['kind']),
      items: items,
      createdAt: created,
      updatedAt: _time(json['updatedAt']) ?? created,
      deletedAt: deleted,
    );
  }

  static PlaylistKind _kind(Object? raw) {
    for (final kind in PlaylistKind.values) {
      if (kind.name == raw) return kind;
    }
    return PlaylistKind.user;
  }

  static DateTime? _time(Object? raw) =>
      raw is String ? DateTime.tryParse(raw) : null;

  static final DateTime _epoch = DateTime.utc(1970);
}
