import 'package:flutter/foundation.dart';
import '../models/connection_status.dart';
import 'secure_token_store.dart';
import 'server_api.dart';

/// Holds the saved-token flag and the last server check for the UI.
/// Never exposes the token itself, and never checks on its own.
class ConnectionService extends ChangeNotifier {
  ConnectionService({
    required ServerApi api,
    required TokenStore tokenStore,
  })  : _api = api,
        _tokenStore = tokenStore;

  final ServerApi _api;
  final TokenStore _tokenStore;

  ConnectionStatus _status = ConnectionStatus.unknown;
  bool _hasToken = false;

  ConnectionStatus get status => _status;
  bool get hasToken => _hasToken;

  /// Reads whether a token is saved. Never throws, so startup is safe.
  Future<void> load() async {
    try {
      final token = await _tokenStore.readToken();
      _hasToken = token != null && token.trim().isNotEmpty;
    } catch (_) {
      _hasToken = false;
    }
    notifyListeners();
  }

  /// Saves the token, then checks the server. Returns false if nothing
  /// was saved (blank input or a storage failure).
  Future<bool> saveAndTest(String token) async {
    final value = token.trim();
    if (value.isEmpty) return false;

    try {
      await _tokenStore.writeToken(value);
    } catch (_) {
      _status = ConnectionStatus.unexpected;
      notifyListeners();
      return false;
    }

    _hasToken = true;
    await check();
    return true;
  }

  Future<void> check() async {
    if (!_hasToken || _status == ConnectionStatus.checking) return;

    _status = ConnectionStatus.checking;
    notifyListeners();

    final result = await _api.healthCheck();
    _status = switch (result) {
      ServerOk() => ConnectionStatus.connected,
      ServerUnauthorized() => ConnectionStatus.badToken,
      ServerUnavailable() => ConnectionStatus.unreachable,
      ServerUnexpected() => ConnectionStatus.unexpected,
    };
    notifyListeners();
  }

  Future<void> forget() async {
    try {
      await _tokenStore.deleteToken();
    } catch (_) {
      _status = ConnectionStatus.unexpected;
      notifyListeners();
      return;
    }
    _hasToken = false;
    _status = ConnectionStatus.unknown;
    notifyListeners();
  }
}
