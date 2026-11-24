import '../models/track.dart';
import 'track_key.dart';

/// The queue now playing, brought in line with the playlist it came from.
///
/// Songs that are still there keep their own [Track] object (the player
/// recognises the song it is loading by that object), and new songs are put
/// where the playlist has them. Nothing here touches audio, so the rules can
/// be tested on their own.
class QueueSync {
  const QueueSync._({
    required this.queue,
    required this.oldToNew,
    required this.added,
    required this.changed,
  });

  /// The queue after the change.
  final List<Track> queue;

  /// For each position in the old queue, where it is now, or null when the
  /// song is gone.
  final List<int?> oldToNew;

  /// The positions in [queue] of songs that were not in the old queue.
  final List<int> added;

  /// False when the queue is exactly what it was.
  final bool changed;

  /// Compares the playing queue with the playlist.
  ///
  /// [wanted] is what the playlist can play now, in its order. [inPlaylist]
  /// is the key of every line the playlist has, so that a local song which is
  /// in the playlist but not on this device (yet) is not thrown out of the
  /// queue. The song at [playing] is never thrown out either: it finishes
  /// first, even when it has just been taken out of the playlist.
  factory QueueSync.compute({
    required List<Track> oldQueue,
    required int playing,
    required List<Track> wanted,
    required Set<String> inPlaylist,
  }) {
    final pool = <String, List<int>>{};
    for (var i = 0; i < oldQueue.length; i++) {
      pool.putIfAbsent(oldQueue[i].playlistKey, () => []).add(i);
    }

    final entries = <_Entry>[];
    final matched = <int>{};
    for (final track in wanted) {
      final spare = pool[track.playlistKey];
      if (spare != null && spare.isNotEmpty) {
        final old = spare.removeAt(0);
        matched.add(old);
        entries.add(_Entry(oldQueue[old], old));
      } else {
        entries.add(_Entry(track, null));
      }
    }

    // Songs that stay although the playlist did not hand them over: the one
    // playing, and a song the playlist has but this device cannot play yet.
    final handedOver = {for (final track in wanted) track.playlistKey};
    for (var old = 0; old < oldQueue.length; old++) {
      if (matched.contains(old)) continue;
      final key = oldQueue[old].playlistKey;
      final stays =
          old == playing ||
          (inPlaylist.contains(key) && !handedOver.contains(key));
      if (!stays) continue;
      var at = entries.length;
      for (var j = old + 1; j < oldQueue.length; j++) {
        final found = entries.indexWhere((e) => e.old == j);
        if (found >= 0) {
          at = found;
          break;
        }
      }
      entries.insert(at, _Entry(oldQueue[old], old));
    }

    final oldToNew = List<int?>.filled(oldQueue.length, null);
    final added = <int>[];
    var changed = entries.length != oldQueue.length;
    for (var i = 0; i < entries.length; i++) {
      final old = entries[i].old;
      if (old == null) {
        added.add(i);
        changed = true;
      } else {
        oldToNew[old] = i;
        if (old != i) changed = true;
      }
    }
    return QueueSync._(
      queue: [for (final entry in entries) entry.track],
      oldToNew: oldToNew,
      added: added,
      changed: changed,
    );
  }
}

class _Entry {
  _Entry(this.track, this.old);

  final Track track;

  /// Its position in the old queue, or null for a song that is new.
  final int? old;
}
