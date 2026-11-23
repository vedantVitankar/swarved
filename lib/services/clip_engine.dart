import 'dart:io';

/// How a clip's turn on the audio player ended.
enum ClipEnd {
  /// Still going (or paused). Not over.
  none,

  /// It played to its last second.
  finished,

  /// Something else (a song, a voice between songs) started on the audio
  /// player, so the clip is gone.
  taken,
}

/// Where a clip is, as the audio player reports it.
class ClipStatus {
  final Duration position;
  final Duration duration;
  final bool playing;
  final ClipEnd end;

  const ClipStatus({
    required this.position,
    required this.duration,
    required this.playing,
    this.end = ClipEnd.none,
  });
}

/// What a short clip (a letter's recording) needs from the audio player.
///
/// A clip is played outside the song queue: it never touches the queue, the
/// order, the listening stats or the saved queue. Opening one pauses the
/// music, and closing it leaves the music paused, ready for her to press
/// play where she left it. Nothing resumes on its own.
///
/// This is its own small contract so the letter's controls can be tested
/// without a real audio player.
abstract class ClipEngine {
  /// Position, length and play state while a clip is open, and the moment it
  /// finishes or is taken over.
  Stream<ClipStatus> get clipStatus;

  /// Pauses the music and loads [file], paused. [title] and [artist] are what
  /// the phone's media notification shows. Throws if it cannot be loaded; the
  /// music then stays paused.
  Future<void> openClip(
    File file, {
    required String title,
    required String artist,
  });

  /// Starts or continues the open clip. Returns once it is under way, not
  /// when it ends.
  Future<void> playClip();

  Future<void> pauseClip();

  Future<void> seekClip(Duration to);

  /// Stops the clip and gives the audio player back. The music stays paused.
  /// Does nothing when no clip is open.
  Future<void> closeClip();
}
