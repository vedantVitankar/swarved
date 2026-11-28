import 'youtube_result.dart';

/// Why a YouTube playlist could not be imported.
enum PlaylistImportProblem {
  /// The text is not a link to a YouTube playlist.
  badLink,

  /// YouTube's endless auto-made "Mix".
  mix,

  /// Liked music or Watch later: private to a YouTube account.
  privateList,

  /// Private, deleted, empty or not there.
  unavailable,
}

/// A YouTube playlist as the server read it. Titles are YouTube's own.
class ImportedPlaylist {
  const ImportedPlaylist({
    required this.title,
    required this.songs,
    this.skipped = 0,
    this.truncated = false,
  });

  /// Empty when YouTube gave the playlist no name.
  final String title;
  final List<YoutubeResult> songs;

  /// Private or deleted songs that were left out.
  final int skipped;

  /// The playlist is longer than what was read, so only the first songs came.
  final bool truncated;
}

/// What the server answers to "read this playlist": the playlist, or the
/// reason it can't be imported.
class PlaylistImportAnswer {
  const PlaylistImportAnswer.found(ImportedPlaylist this.playlist)
      : problem = null;
  const PlaylistImportAnswer.refused(PlaylistImportProblem this.problem)
      : playlist = null;

  final ImportedPlaylist? playlist;
  final PlaylistImportProblem? problem;

  /// Reads the server's answer. Throws a FormatException when it is not
  /// shaped as expected, so one odd answer never becomes a broken playlist.
  static PlaylistImportAnswer parse(Object? body) {
    if (body is! Map<String, dynamic>) {
      throw const FormatException('playlist answer is not an object');
    }

    if (body['ok'] == false) {
      return PlaylistImportAnswer.refused(switch (body['reason']) {
        'bad_link' => PlaylistImportProblem.badLink,
        'mix' => PlaylistImportProblem.mix,
        'private' => PlaylistImportProblem.privateList,
        'unavailable' => PlaylistImportProblem.unavailable,
        _ => throw const FormatException('unknown reason'),
      });
    }
    if (body['ok'] != true) {
      throw const FormatException('playlist answer has no ok');
    }

    final raw = body['songs'];
    if (raw is! List) {
      throw const FormatException('playlist answer has no songs list');
    }
    final seen = <String>{};
    final songs = <YoutubeResult>[];
    for (final item in raw) {
      final song = YoutubeResult.tryParse(item);
      if (song != null && seen.add(song.id)) songs.add(song);
    }
    if (songs.isEmpty) {
      return const PlaylistImportAnswer.refused(
        PlaylistImportProblem.unavailable,
      );
    }

    final title = body['title'];
    final skipped = body['skipped'];
    return PlaylistImportAnswer.found(
      ImportedPlaylist(
        title: title is String ? title.trim() : '',
        songs: songs,
        skipped: skipped is int && skipped > 0 ? skipped : 0,
        truncated: body['truncated'] == true,
      ),
    );
  }
}
