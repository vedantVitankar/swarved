import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/models/track.dart';
import 'package:swarved/services/content_service.dart';

final _track = Track(
  filePath: '/music/Kesariya.mp3',
  title: 'Kesariya',
  artist: 'Artist',
  album: '',
  duration: const Duration(minutes: 3),
  folder: 'music',
);

void main() {
  group('ContentService', () {
    test('loads notes and tells listeners', () async {
      final service = ContentService(
        loader: () async => '{"notes":[{"title":"Kesariya","note":"Ours."}]}',
      );
      var told = 0;
      service.addListener(() => told++);

      await service.load();

      expect(service.noteFor(_track)?.note, 'Ours.');
      expect(told, 1);
    });

    test('a broken file leaves it empty and does not throw', () async {
      final service = ContentService(loader: () async => 'not json');
      await service.load();
      expect(service.noteFor(_track), isNull);
    });

    test('a loader that fails leaves it empty and does not throw', () async {
      final service = ContentService(loader: () async => throw Exception('no'));
      await service.load();
      expect(service.pack.notes, isEmpty);
    });
  });
}
