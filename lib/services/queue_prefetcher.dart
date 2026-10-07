import 'dart:async';

import '../models/prefetch_mode.dart';
import '../models/track.dart';
import 'server_api.dart';

/// Asks the server to download the song that plays next, so it starts from
/// the server's disk instead of waiting on YouTube. It waits a while before
/// asking, and a newer song cancels the wait, so skipping through songs
/// never downloads any of them. Every failure is ignored: this only makes
/// things faster, and playback never depends on it.
class QueuePrefetcher {
  QueuePrefetcher({
    required ServerApi api,
    Duration delay = const Duration(seconds: 10),
  })  : _api = api,
        _delay = delay;

  final ServerApi _api;
  final Duration _delay;

  Timer? _timer;

  /// The last song the server accepted a request for, so the same song is
  /// not asked for again and again.
  String? _requestedId;

  /// Replaces any pending request with one for [next]. A null or local
  /// song means nothing needs preparing.
  void schedule(Track? next) {
    cancel();
    final videoId = next?.videoId;
    if (next == null || next.isLocal || videoId == null) return;
    if (videoId == _requestedId) return;
    _timer = Timer(_delay, () => unawaited(_request(videoId)));
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _request(String videoId) async {
    _timer = null;
    try {
      final result = await _api.prefetch([videoId], mode: PrefetchMode.full);
      if (result is ServerOk<List<String>>) _requestedId = videoId;
    } catch (_) {
      // Nothing to tell the listener: the song will simply load as before.
    }
  }

  void dispose() => cancel();
}
