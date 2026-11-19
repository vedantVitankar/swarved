import 'dart:math' as math;

import 'track.dart';
import 'track_source.dart';

/// What was playing when the app last stopped, so it can be put back: the
/// songs in the queue, where in it she was, the play order (so a shuffled
/// queue carries on in the same sequence), how far into the song, and which
/// playlist it came from.
///
/// Plain data with no audio in it. It is written as JSON by
/// [toJson] and read back by [tryParse], which never throws: anything it
/// cannot make sense of is simply "nothing saved".
class SavedQueue {
  const SavedQueue({
    required this.tracks,
    required this.index,
    required this.position,
    required this.savedAt,
    this.order,
    this.sourceName,
    this.sourcePlaylistId,
  });

  /// Bumped if the saved shape ever changes. A file from a newer app than
  /// this one is ignored rather than half understood.
  static const int version = 1;

  /// More than this is not a queue she built, so nothing is saved for it.
  static const int maxTracks = 2000;

  final List<Track> tracks;

  /// Which song in [tracks] was playing (an index into the queue, not into
  /// the play order).
  final int index;

  /// How far into that song she was.
  final Duration position;

  /// The play order from `QueueOrder.toJson`, or null to start a fresh one.
  final Map<String, Object?>? order;

  /// The playlist it came from, for the "Playing from ..." line.
  final String? sourceName;
  final String? sourcePlaylistId;

  final DateTime savedAt;

  Track get current => tracks[index];

  Map<String, Object?> toJson() => {
        'version': version,
        'savedAt': savedAt.toUtc().toIso8601String(),
        'index': index,
        'positionMs': position.inMilliseconds,
        'order': order,
        'source': sourceName == null
            ? null
            : {'name': sourceName, 'playlistId': sourcePlaylistId},
        'tracks': [for (final track in tracks) _trackToJson(track)],
      };

  /// The saved queue in [raw] (decoded JSON), or null when there is none or
  /// it is damaged, from a newer app, or does not make sense.
  static SavedQueue? tryParse(Object? raw) {
    try {
      return _parse(raw);
    } catch (_) {
      return null; // anything unexpected is "nothing saved"
    }
  }

  static SavedQueue? _parse(Object? raw) {
    if (raw is! Map || raw['version'] != version) return null;

    final rawTracks = raw['tracks'];
    if (rawTracks is! List ||
        rawTracks.isEmpty ||
        rawTracks.length > maxTracks) {
      return null;
    }
    final tracks = <Track>[];
    for (final entry in rawTracks) {
      final track = _trackFromJson(entry);
      if (track == null) return null; // one bad song spoils the sequence
      tracks.add(track);
    }

    final index = raw['index'];
    if (index is! int || index < 0 || index >= tracks.length) return null;

    final positionMs = raw['positionMs'];
    if (positionMs is! int || positionMs < 0) return null;
    var position = Duration(milliseconds: positionMs);
    final length = tracks[index].duration;
    // Saved at (or past) the very end: start that song again, not at silence.
    if (length > Duration.zero && position >= length) position = Duration.zero;

    final order = raw['order'];
    final savedAt = DateTime.tryParse('${raw['savedAt']}');

    String? sourceName;
    String? sourcePlaylistId;
    final source = raw['source'];
    if (source is Map) {
      final name = source['name'];
      final id = source['playlistId'];
      if (name is String && name.isNotEmpty) sourceName = name;
      if (id is String && id.isNotEmpty) sourcePlaylistId = id;
    }

    return SavedQueue(
      tracks: tracks,
      index: index,
      position: position,
      order: order is Map ? Map<String, Object?>.from(order) : null,
      sourceName: sourceName,
      sourcePlaylistId: sourcePlaylistId,
      savedAt: savedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  /// The same queue with each song replaced by [change] (for putting back the
  /// artwork of local songs from the library). Nothing else moves.
  SavedQueue mapTracks(Track Function(Track) change) => SavedQueue(
        tracks: [for (final track in tracks) change(track)],
        index: index,
        position: position,
        order: order,
        sourceName: sourceName,
        sourcePlaylistId: sourcePlaylistId,
        savedAt: savedAt,
      );

  /// The queue without the songs [keep] says are gone (a file she deleted).
  /// Null when none are left.
  ///
  /// If every song is still there this is the same queue. Otherwise the saved
  /// play order no longer fits, so [order] is dropped and a fresh one is made
  /// from the songs that remain. If the song that was playing is among the
  /// gone ones, the next one that remains takes over, from its start.
  SavedQueue? keeping(bool Function(Track) keep) {
    final kept = <Track>[];
    var keptBefore = 0;
    int? nowIndex;
    for (var i = 0; i < tracks.length; i++) {
      if (!keep(tracks[i])) continue;
      if (i == index) nowIndex = kept.length;
      if (i < index) keptBefore++;
      kept.add(tracks[i]);
    }
    if (kept.isEmpty) return null;
    if (kept.length == tracks.length) return this;

    final songGone = nowIndex == null;
    return SavedQueue(
      tracks: kept,
      index: nowIndex ?? math.min(keptBefore, kept.length - 1),
      position: songGone ? Duration.zero : position,
      order: null,
      sourceName: sourceName,
      sourcePlaylistId: sourcePlaylistId,
      savedAt: savedAt,
    );
  }

  static Map<String, Object?> _trackToJson(Track track) => track.isLocal
      ? {
          'kind': 'local',
          'path': track.filePath,
          'title': track.title,
          'artist': track.artist,
          'album': track.album,
          'folder': track.folder,
          'ms': track.duration.inMilliseconds,
        }
      : {
          'kind': 'youtube',
          'videoId': track.videoId,
          'title': track.title,
          'artist': track.artist,
          'ms': track.duration.inMilliseconds,
          'art': track.artworkUrl,
        };

  static Track? _trackFromJson(Object? raw) {
    if (raw is! Map) return null;
    final title = raw['title'];
    final artist = raw['artist'];
    final ms = raw['ms'];
    if (title is! String || artist is! String || ms is! int || ms < 0) {
      return null;
    }
    final duration = Duration(milliseconds: ms);

    switch (raw['kind']) {
      case 'youtube':
        final videoId = raw['videoId'];
        if (videoId is! String || videoId.isEmpty) return null;
        final art = raw['art'];
        return Track.youtube(
          videoId: videoId,
          title: title,
          artist: artist,
          duration: duration,
          artworkUrl: art is String && art.isNotEmpty ? art : null,
        );
      case 'local':
        final path = raw['path'];
        final album = raw['album'];
        final folder = raw['folder'];
        if (path is! String || path.isEmpty) return null;
        return Track(
          filePath: path,
          title: title,
          artist: artist,
          album: album is String ? album : '',
          duration: duration,
          folder: folder is String ? folder : '',
          source: TrackSource.local,
        );
    }
    return null;
  }
}
