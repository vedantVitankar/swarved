import 'dart:async';

import 'package:flutter/foundation.dart';

import 'content_cache.dart';
import 'content_service.dart';
import 'content_source.dart';

/// Keeps the app's content the same as what he last published, while the
/// app is open.
///
/// At start the copy kept on the phone is applied, so everything is there
/// at once. Then the app asks the server for the newest content. After that
/// it holds one request open: the server answers the moment he clicks
/// Publish, the new content is applied, and the app asks again. Everything
/// on screen listens to [ContentService], so it changes without a restart.
///
/// While the app is in the background nothing is asked. On return the app
/// catches up first.
class ContentSync {
  ContentSync({
    required ContentSource source,
    required ContentCache cache,
    required ContentService content,
    this.onMedia,
    Duration minGap = const Duration(seconds: 1),
    Future<void> Function(Duration)? sleep,
  })  : _source = source,
        _cache = cache,
        _content = content,
        _minGap = minGap,
        _sleep = sleep ?? Future<void>.delayed;

  final ContentSource _source;
  final ContentCache _cache;
  final ContentService _content;
  final Duration _minGap;
  final Future<void> Function(Duration) _sleep;

  /// Told which uploaded files the content uses, so they can be fetched
  /// ahead of time. [fromServer] is false for the copy kept on the phone,
  /// which is only a reason to fetch, never to tidy anything away. Optional.
  final Future<void> Function(Set<String> names, bool fromServer)? onMedia;

  /// The tag of the content the app has now.
  String? _etag;

  /// True until the app has asked once, and after a failure or a return from
  /// the background: the next request answers at once instead of waiting.
  bool _catchUp = true;

  int _failures = 0;
  bool _started = false;
  bool _stopped = false;
  bool _paused = false;
  Completer<void> _abort = Completer<void>();
  Completer<void>? _resume;
  Completer<void>? _wake;

  /// How long to rest after the [count]th failure in a row.
  @visibleForTesting
  static Duration restAfter(ContentFailure reason, int count) {
    switch (reason) {
      case ContentFailure.aborted:
        return Duration.zero;
      case ContentFailure.unauthorized:
      case ContentFailure.unexpected:
        return const Duration(seconds: 30);
      case ContentFailure.unavailable:
        // 5, 10, 20, 40, then a minute at most.
        final doublings = count <= 1 ? 0 : (count > 5 ? 4 : count - 1);
        final seconds = 5 * (1 << doublings);
        return Duration(seconds: seconds > 60 ? 60 : seconds);
    }
  }

  /// Applies the copy kept on the phone, if there is one. Call it before the
  /// first screen is drawn.
  Future<void> loadCache() async {
    final cached = await _cache.read();
    if (cached == null) return;
    if (_content.apply(cached.body)) {
      _etag = cached.etag.isEmpty ? null : cached.etag;
      _tellMedia(fromServer: false);
    }
  }

  /// Starts keeping the content up to date. Does nothing the second time.
  void start() {
    if (_started) return;
    _started = true;
    unawaited(_loop());
  }

  /// Something that was stopping the app from asking has changed (a token
  /// was just saved, say): if it is resting after a failure, try again now.
  void poke() {
    final wake = _wake;
    if (wake != null && !wake.isCompleted) wake.complete();
  }

  /// The app went to the background: stop asking, and cancel the request
  /// that is waiting.
  void pause() {
    if (_paused || _stopped) return;
    _paused = true;
    if (!_abort.isCompleted) _abort.complete();
  }

  /// The app is back: catch up first, then wait again.
  void resume() {
    if (!_paused) return;
    _paused = false;
    _abort = Completer<void>();
    _catchUp = true;
    final gate = _resume;
    if (gate != null && !gate.isCompleted) gate.complete();
  }

  void stop() {
    _stopped = true;
    if (!_abort.isCompleted) _abort.complete();
    final gate = _resume;
    if (gate != null && !gate.isCompleted) gate.complete();
  }

  Future<void> _loop() async {
    while (!_stopped) {
      if (_paused) {
        final gate = _resume = Completer<void>();
        await gate.future;
        _resume = null;
        continue;
      }
      final rest = await syncOnce();
      if (_stopped) break;
      if (rest > Duration.zero) {
        final wake = _wake = Completer<void>();
        await Future.any<void>([_sleep(rest), wake.future]);
        _wake = null;
      }
    }
  }

  /// One request and what follows from its answer. Returns how long to rest
  /// before the next one.
  @visibleForTesting
  Future<Duration> syncOnce() async {
    final result = await _source.fetch(
      etag: _etag,
      wait: !_catchUp,
      abortTrigger: _abort.future,
    );

    switch (result) {
      case ContentNew(:final body, :final etag):
        _catchUp = false;
        if (!_content.apply(body)) {
          return _failed(ContentFailure.unexpected);
        }
        _failures = 0;
        _etag = etag.isEmpty ? null : etag;
        await _remember(body, etag);
        debugPrint('Content: new content applied ($etag)');
        _tellMedia(fromServer: true);
        return _minGap;
      case ContentUnchanged():
      case ContentNothingPublished():
        _catchUp = false;
        _failures = 0;
        return _minGap;
      case ContentFailed(:final reason):
        if (reason == ContentFailure.aborted) return Duration.zero;
        return _failed(reason);
    }
  }

  Duration _failed(ContentFailure reason) {
    _failures++;
    _catchUp = true;
    final rest = restAfter(reason, _failures);
    debugPrint('Content: not fetched ($reason), trying again in '
        '${rest.inSeconds}s');
    return rest;
  }

  Future<void> _remember(String body, String etag) async {
    try {
      await _cache.write(CachedContent(body: body, etag: etag));
    } catch (error) {
      // The content is applied; only the copy for next time is lost.
      debugPrint('Content copy not saved: $error');
    }
  }

  void _tellMedia({required bool fromServer}) {
    final tell = onMedia;
    if (tell == null) return;
    unawaited(tell(_content.mediaFiles, fromServer));
  }
}
