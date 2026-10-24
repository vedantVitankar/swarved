import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/services/bundled_token_store.dart';
import 'package:swarved/services/secure_token_store.dart';

class _FakeTokenStore implements TokenStore {
  _FakeTokenStore({this.token, this.failWrites = false});

  String? token;
  final bool failWrites;
  int writes = 0;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String value) async {
    if (failWrites) throw StateError('storage broke');
    writes++;
    token = value;
  }

  @override
  Future<void> deleteToken() async => token = null;
}

void main() {
  group('BundledTokenStore', () {
    test('without a bundled token it is just the inner store', () async {
      final inner = _FakeTokenStore(token: 'typed');
      final store = BundledTokenStore(inner: inner, bundled: '');

      expect(await store.readToken(), 'typed');
      expect(inner.writes, 0);
    });

    test('without a bundled token and nothing saved there is no token',
        () async {
      final store = BundledTokenStore(inner: _FakeTokenStore(), bundled: '  ');

      expect(await store.readToken(), isNull);
    });

    test('a bundled token is used when nothing is saved, and saved', () async {
      final inner = _FakeTokenStore();
      final store = BundledTokenStore(inner: inner, bundled: 'baked');

      expect(await store.readToken(), 'baked');
      expect(inner.token, 'baked');
    });

    test('a bundled token wins over an older saved one', () async {
      final inner = _FakeTokenStore(token: 'old');
      final store = BundledTokenStore(inner: inner, bundled: 'new');

      expect(await store.readToken(), 'new');
      expect(inner.token, 'new');
    });

    test('a matching saved token is not written again', () async {
      final inner = _FakeTokenStore(token: 'same');
      final store = BundledTokenStore(inner: inner, bundled: 'same');

      expect(await store.readToken(), 'same');
      expect(inner.writes, 0);
    });

    test('the bundled token is trimmed', () async {
      final store =
          BundledTokenStore(inner: _FakeTokenStore(), bundled: '  baked \n');

      expect(await store.readToken(), 'baked');
    });

    test('a storage failure still returns the bundled token', () async {
      final store = BundledTokenStore(
        inner: _FakeTokenStore(failWrites: true),
        bundled: 'baked',
      );

      expect(await store.readToken(), 'baked');
    });

    test('write and delete go to the inner store', () async {
      final inner = _FakeTokenStore();
      final store = BundledTokenStore(inner: inner, bundled: '');

      await store.writeToken('typed');
      expect(inner.token, 'typed');
      await store.deleteToken();
      expect(inner.token, isNull);
    });
  });
}
