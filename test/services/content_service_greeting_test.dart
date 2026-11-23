import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/services/content_service.dart';

DateTime _at(int hour, [int minute = 0]) => DateTime(2026, 11, 23, hour, minute);

Future<ContentService> _with(String json) async {
  final service = ContentService(loader: () async => json);
  await service.load();
  return service;
}

void main() {
  group('ContentService greetings', () {
    test('without any, the app\'s own greeting is used at every hour', () async {
      final service = await _with('{}');

      expect(service.greetingFor(_at(8)), isNull);
      expect(service.greetingText(_at(8)), 'Good morning,\nSwarnima');
      expect(service.greetingText(_at(13)), 'Hey,\nSwara');
      expect(service.greetingText(_at(19)), 'Good evening,\nSwara');
      expect(service.greetingText(_at(23)), 'Still up,\nbaby?');
      expect(service.greetingText(_at(3)), 'Still up,\nbaby?');
    });

    test('his greeting replaces the app\'s for its hours only', () async {
      final service = await _with('''{"greetings": [
        {"from": "05:00", "to": "12:00", "text": "Rise,\\nsun", "gold": "Up already"}
      ]}''');

      expect(service.greetingText(_at(8)), 'Rise,\nsun');
      expect(service.greetingFor(_at(8))!.gold, 'Up already');
      // Outside his hours the app's own comes back.
      expect(service.greetingText(_at(13)), 'Hey,\nSwara');
      expect(service.greetingFor(_at(13)), isNull);
    });

    test('a wide window gets one line', () async {
      final service = await _with(
          '{"greetings": [{"from": "05:00", "to": "12:00", "text": "Rise,\\nsun"}]}');

      expect(service.greetingText(_at(8), oneLine: true), 'Rise, sun');
      expect(service.greetingText(_at(13), oneLine: true), 'Hey, Swara');
    });
  });
}
