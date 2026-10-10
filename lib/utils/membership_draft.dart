import '../models/playlist.dart';

/// A playlist she typed a name for in the popup. It does not exist yet: it
/// is only made when she presses Done, and only if it is still ticked.
class StagedPlaylist {
  StagedPlaylist(this.name);

  final String name;
  bool chosen = true;
}

/// The ticks in the playlist popup, before she presses Done.
///
/// Every tap only changes this draft. Nothing is saved until the popup hands
/// [playlistIds] and [newNames] to the playlist service, so a tick she
/// cleared and ticked again leaves the playlist exactly as it was, with the
/// song in its old place.
class MembershipDraft {
  MembershipDraft(Set<String> alreadyIn)
      : _start = Set.of(alreadyIn),
        _chosen = Set.of(alreadyIn);

  final Set<String> _start;
  final Set<String> _chosen;
  final List<StagedPlaylist> _staged = [];

  bool isChosen(String playlistId) => _chosen.contains(playlistId);

  /// Ticks a playlist, or clears its tick.
  void toggle(String playlistId) {
    if (!_chosen.remove(playlistId)) _chosen.add(playlistId);
  }

  /// Newest first, the way new playlists are listed.
  List<StagedPlaylist> get staged => List.unmodifiable(_staged.reversed);

  /// Adds a playlist to be made on Done, already ticked. False for a name
  /// with nothing in it. A name already staged (capitals aside) is ticked
  /// again instead of staged twice.
  bool addNew(String raw) {
    final name = Playlist.cleanName(raw);
    if (name.isEmpty) return false;
    final lower = name.toLowerCase();
    for (final existing in _staged) {
      if (existing.name.toLowerCase() == lower) {
        existing.chosen = true;
        return true;
      }
    }
    _staged.add(StagedPlaylist(name));
    return true;
  }

  void toggleStaged(StagedPlaylist playlist) =>
      playlist.chosen = !playlist.chosen;

  /// The playlists the song should be in, among those that already exist.
  Set<String> get playlistIds => Set.of(_chosen);

  /// The names of the playlists to make, oldest first, so the newest ends
  /// up first in the list.
  List<String> get newNames => [
        for (final playlist in _staged)
          if (playlist.chosen) playlist.name,
      ];

  /// Whether Done would change anything at all.
  bool get hasChanges =>
      _start.length != _chosen.length ||
      !_start.containsAll(_chosen) ||
      _staged.any((playlist) => playlist.chosen);
}
