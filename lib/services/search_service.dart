import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/youtube_result.dart';
import '../models/youtube_search_status.dart';
import '../utils/search_query.dart';
import 'server_api.dart';

/// The YouTube half of a search. It waits for a pause in typing, asks the
/// server, and throws away answers to questions that are no longer current.
/// Local results are not here: they are filtered straight from the library.
/// Searching never downloads anything.
class SearchService extends ChangeNotifier {
  SearchService({
    required ServerApi api,
    Duration debounce = const Duration(milliseconds: 350),
    int limit = 10,
  })  : _api = api,
        _debounce = debounce,
        _limit = limit;

  final ServerApi _api;
  final Duration _debounce;
  final int _limit;

  String _query = '';
  YoutubeSearchStatus _status = YoutubeSearchStatus.idle;
  List<YoutubeResult> _results = const [];

  Timer? _timer;
  Completer<void>? _abort;

  /// Bumped whenever the current search is replaced or cancelled. An answer
  /// that comes back under an older number is stale and is ignored.
  int _generation = 0;

  /// What is being searched for, cleaned up (see normalizeQuery).
  String get query => _query;
  YoutubeSearchStatus get status => _status;

  /// The last answer. While a newer search is loading these are still the
  /// previous results, so the list doesn't flash empty between keystrokes.
  List<YoutubeResult> get results => _results;

  /// Called on every keystroke. Only a real change starts a new search.
  void onQueryChanged(String raw) {
    final query = normalizeQuery(raw);
    if (query == _query) return;

    _query = query;
    _supersede();

    if (query.isEmpty) {
      _results = const [];
      _status = YoutubeSearchStatus.idle;
    } else {
      _status = YoutubeSearchStatus.loading;
      _timer = Timer(_debounce, () => unawaited(_run()));
    }
    notifyListeners();
  }

  /// Search right now, without waiting for the pause. For the Enter key and
  /// the Try again button.
  void searchNow() {
    if (_query.isEmpty) return;
    _supersede();
    _status = YoutubeSearchStatus.loading;
    notifyListeners();
    unawaited(_run());
  }

  Future<void> _run() async {
    _timer = null;
    final generation = _generation;
    final query = _query;
    final abort = Completer<void>();
    _abort = abort;

    ServerResult<List<YoutubeResult>> result;
    try {
      result = await _api.searchSongs(
        query,
        limit: _limit,
        abortTrigger: abort.future,
      );
    } catch (_) {
      result = const ServerUnexpected<List<YoutubeResult>>();
    }

    if (generation != _generation) return; // a newer search took over
    _abort = null;

    switch (result) {
      case ServerOk<List<YoutubeResult>>(:final value):
        _results = value;
        _status = YoutubeSearchStatus.loaded;
      case ServerUnauthorized<List<YoutubeResult>>():
        _results = const [];
        _status = YoutubeSearchStatus.unauthorized;
      case ServerUnavailable<List<YoutubeResult>>():
        _results = const [];
        _status = YoutubeSearchStatus.unreachable;
      case ServerUnexpected<List<YoutubeResult>>():
        _results = const [];
        _status = YoutubeSearchStatus.unexpected;
    }
    notifyListeners();
  }

  /// Cancels the waiting timer and any request in flight.
  void _supersede() {
    _generation++;
    _timer?.cancel();
    _timer = null;

    final abort = _abort;
    _abort = null;
    if (abort != null && !abort.isCompleted) abort.complete();
  }

  @override
  void dispose() {
    _supersede();
    super.dispose();
  }
}
