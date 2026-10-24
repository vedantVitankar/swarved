import 'secure_token_store.dart';

/// A token store for installer builds, where the token travels inside the app
/// so she never has to type it.
///
/// The token comes from the build (`--dart-define=SWARVED_TOKEN=...`, never
/// from the repo). When one is bundled it wins: it is saved over whatever was
/// saved before, so a new installer with a new token fixes an old one.
/// Without one (debug and test builds) this is just the inner store.
class BundledTokenStore implements TokenStore {
  BundledTokenStore({required TokenStore inner, String? bundled})
      : _inner = inner,
        _bundled = (bundled ?? _buildToken).trim();

  static const String _buildToken = String.fromEnvironment('SWARVED_TOKEN');

  final TokenStore _inner;
  final String _bundled;

  @override
  Future<String?> readToken() async {
    final saved = await _inner.readToken();
    if (_bundled.isEmpty || saved == _bundled) return saved;
    try {
      await _inner.writeToken(_bundled);
    } catch (_) {
      // Storage trouble must not stop the app from using its token.
    }
    return _bundled;
  }

  @override
  Future<void> writeToken(String token) => _inner.writeToken(token);

  @override
  Future<void> deleteToken() => _inner.deleteToken();
}
