import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStore {
  Future<String?> readToken();
  Future<void> writeToken(String token);
  Future<void> deleteToken();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'swarved_server_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> writeToken(String token) async {
    final value = token.trim();
    if (value.isEmpty) {
      await deleteToken();
      return;
    }
    await _storage.write(key: _tokenKey, value: value);
  }

  @override
  Future<void> deleteToken() => _storage.delete(key: _tokenKey);
}
