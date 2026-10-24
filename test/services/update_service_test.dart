import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:swarved/services/app_version.dart';
import 'package:swarved/services/secure_token_store.dart';
import 'package:swarved/services/server_config.dart';
import 'package:swarved/services/update_service.dart';
import 'package:swarved/utils/app_profile.dart';

class _Token implements TokenStore {
  _Token(this.token);
  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String value) async => token = value;

  @override
  Future<void> deleteToken() async => token = null;
}

void main() {
  final bytes = List<int>.generate(5000, (i) => i % 251);
  final sha = sha256.convert(bytes).toString();

  Map<String, Object?> manifest([Map<String, Object?> change = const {}]) => {
        'version': '1.0.1',
        'build': 2,
        'file': 'SwarVed-1.0.1-2.exe',
        'size': bytes.length,
        'sha256': sha,
        'notes': 'A little nicer.',
        ...change,
      };

  late Directory dir;
  late List<http.BaseRequest> requests;
  late List<File> launched;
  late int quits;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('swarved_update');
    requests = [];
    launched = [];
    quits = 0;
  });
  tearDown(() => dir.deleteSync(recursive: true));

  http.StreamedResponse reply(List<int> body, int status) =>
      http.StreamedResponse(Stream.value(body), status);

  /// A server that answers the manifest with [check] and the installer with
  /// [file]. Either may be a function for answers that change.
  MockClient server({
    http.StreamedResponse Function()? check,
    http.StreamedResponse Function()? file,
  }) {
    return MockClient.streaming((request, body) async {
      requests.add(request);
      if (request.url.path.endsWith('/api/app-update')) {
        return (check ??
            () => reply(utf8.encode(jsonEncode(manifest())), 200))();
      }
      return (file ?? () => reply(bytes, 200))();
    });
  }

  UpdateService make({
    http.Client? client,
    String? token = 'secret',
    AppVersion? installed = const (version: '1.0.0', build: 1),
    bool supported = true,
    bool launchWorks = true,
    String profile = AppProfile.swarnima,
  }) {
    return UpdateService(
      config: ServerConfig(profile: profile),
      tokenStore: _Token(token),
      installed: () async => installed,
      supported: supported,
      client: client ?? server(),
      folder: () async => dir,
      launch: (file) async {
        launched.add(file);
        return launchWorks;
      },
      quit: () => quits++,
    );
  }

  Directory downloads() => Directory(p.join(dir.path, 'swarved_update'));

  group('check', () {
    test('does nothing where the app cannot update itself', () async {
      final service = make(supported: false);
      await service.check();
      expect(service.status, UpdateStatus.idle);
      expect(requests, isEmpty);
    });

    test('without a token it cannot ask', () async {
      final service = make(token: null);
      await service.check();
      expect(service.status, UpdateStatus.checkFailed);
      expect(requests, isEmpty);
    });

    test('when Windows does not say which version this is, it cannot ask',
        () async {
      final service = make(installed: null);
      await service.check();
      expect(service.status, UpdateStatus.checkFailed);
      expect(requests, isEmpty);
    });

    test('a newer release is offered, and the request is right', () async {
      final service = make();
      await service.check();

      expect(service.status, UpdateStatus.available);
      expect(service.release!.version, '1.0.1');
      expect(service.release!.notes, 'A little nicer.');
      expect(service.installedVersion, (version: '1.0.0', build: 1));
      expect(requests.single.headers['X-Token'], 'secret');
      expect(requests.single.url.queryParameters, {'platform': 'windows'});
    });

    test('the test profile asks for its own releases', () async {
      final service = make(profile: AppProfile.test);
      await service.check();
      expect(requests.single.url.queryParameters,
          {'profile': 'test', 'platform': 'windows'});
    });

    test('the same or an older release is not offered', () async {
      // The server has build 2; this copy is build 2, then build 3.
      for (final installed in [2, 3]) {
        final service = make(
          installed: (version: '1.0.1', build: installed),
        );
        await service.check();
        expect(service.status, UpdateStatus.upToDate, reason: '$installed');
        expect(service.release, isNull);
      }
    });

    test('nothing published (204) means up to date', () async {
      final service = make(client: server(check: () => reply([], 204)));
      await service.check();
      expect(service.status, UpdateStatus.upToDate);
    });

    test('a failed or strange answer is a failed check, never a crash',
        () async {
      final answers = <http.StreamedResponse Function()>[
        () => reply([], 401),
        () => reply([], 500),
        () => reply(utf8.encode('not json'), 200),
        () =>
            reply(utf8.encode(jsonEncode(manifest({'file': '../x.exe'}))), 200),
        () => reply(utf8.encode(jsonEncode([1, 2])), 200),
      ];
      for (final answer in answers) {
        final service = make(client: server(check: answer));
        await service.check();
        expect(service.status, UpdateStatus.checkFailed);
        expect(service.release, isNull);
      }
    });

    test('no connection is a failed check', () async {
      final service = make(
        client: MockClient((_) async => throw const SocketException('down')),
      );
      await service.check();
      expect(service.status, UpdateStatus.checkFailed);
    });

    test('listeners hear the check start and finish', () async {
      final service = make();
      final heard = <UpdateStatus>[];
      service.addListener(() => heard.add(service.status));
      await service.check();
      expect(heard, [UpdateStatus.checking, UpdateStatus.available]);
    });

    test('asking twice at once asks the server once', () async {
      final service = make();
      await Future.wait([service.check(), service.check()]);
      expect(requests, hasLength(1));
    });

    test('being up to date removes a finished update\'s leftovers', () async {
      downloads().createSync(recursive: true);
      File(p.join(downloads().path, 'SwarVed-1.0.0-1.exe'))
          .writeAsBytesSync([1]);
      final service = make(client: server(check: () => reply([], 204)));

      await service.check();
      for (var i = 0; i < 20 && downloads().existsSync(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(downloads().existsSync(), isFalse);
    });
  });

  group('install', () {
    test('does nothing before a release has been found', () async {
      final service = make();
      await service.install();
      expect(service.status, UpdateStatus.idle);
      expect(requests, isEmpty);
      expect(quits, 0);
    });

    test('downloads, verifies, starts the installer and quits', () async {
      final service = make();
      await service.check();
      final heard = <UpdateStatus>[];
      service.addListener(() => heard.add(service.status));

      await service.install();

      expect(heard, contains(UpdateStatus.downloading));
      expect(service.status, UpdateStatus.installing);
      expect(service.progress, 1);
      expect(launched.single.path.endsWith('SwarVed-1.0.1-2.exe'), isTrue);
      expect(launched.single.readAsBytesSync(), bytes);
      expect(quits, 1);

      final fetch = requests.last;
      expect(fetch.url.path, '/api/app-update/file/SwarVed-1.0.1-2.exe');
      expect(fetch.headers['X-Token'], 'secret');
      expect(
        downloads().listSync().map((e) => p.basename(e.path)),
        ['SwarVed-1.0.1-2.exe'],
      );
    });

    test('an installer that is not what the server published is thrown away',
        () async {
      final wrong = List<int>.from(bytes)..[10] = 0;
      final service = make(client: server(file: () => reply(wrong, 200)));
      await service.check();
      await service.install();

      expect(service.status, UpdateStatus.downloadFailed);
      expect(launched, isEmpty);
      expect(quits, 0);
      expect(downloads().listSync(), isEmpty);
    });

    test('a short download is thrown away', () async {
      final service = make(
        client: server(file: () => reply(bytes.sublist(0, 100), 200)),
      );
      await service.check();
      await service.install();

      expect(service.status, UpdateStatus.downloadFailed);
      expect(launched, isEmpty);
      expect(downloads().listSync(), isEmpty);
    });

    test('a server that does not have it is a failed download', () async {
      final service = make(client: server(file: () => reply([], 404)));
      await service.check();
      await service.install();

      expect(service.status, UpdateStatus.downloadFailed);
      expect(launched, isEmpty);
      expect(quits, 0);
    });

    test('an installer that will not start leaves the app running', () async {
      final service = make(launchWorks: false);
      await service.check();
      await service.install();

      expect(service.status, UpdateStatus.downloadFailed);
      expect(quits, 0);
    });

    test('after a failure it can be tried again', () async {
      var tries = 0;
      final service = make(
        client: server(
            file: () => ++tries == 1 ? reply([], 500) : reply(bytes, 200)),
      );
      await service.check();
      await service.install();
      expect(service.status, UpdateStatus.downloadFailed);
      expect(service.release, isNotNull);

      await service.install();
      expect(service.status, UpdateStatus.installing);
      expect(quits, 1);
    });

    test('a second tap while it works does nothing', () async {
      final service = make();
      await service.check();
      await Future.wait([service.install(), service.install()]);
      expect(launched, hasLength(1));
      expect(quits, 1);
    });
  });
}
