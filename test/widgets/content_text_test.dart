import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:swarved/services/content_service.dart';
import 'package:swarved/widgets/content_text.dart';

Future<ContentService> _service(String json) async {
  final service = ContentService(loader: () async => json);
  await service.load();
  return service;
}

Widget _app(ContentService service) {
  return ChangeNotifierProvider<ContentService>.value(
    value: service,
    child: const MaterialApp(
      home: Scaffold(
        body: ContentText(textKey: 'searchTitle', fallback: 'The app\'s own'),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the app\'s own words when he wrote none', (tester) async {
    final service = await _service('{}');

    await tester.pumpWidget(_app(service));

    expect(find.text('The app\'s own'), findsOneWidget);
  });

  testWidgets('shows his words when he wrote some', (tester) async {
    final service = await _service('{"texts": {"searchTitle": "Hello, baby"}}');

    await tester.pumpWidget(_app(service));

    expect(find.text('Hello, baby'), findsOneWidget);
    expect(find.text('The app\'s own'), findsNothing);
  });

  testWidgets('changes the moment new content is applied', (tester) async {
    final service = await _service('{}');
    await tester.pumpWidget(_app(service));
    expect(find.text('The app\'s own'), findsOneWidget);

    service.apply('{"texts": {"searchTitle": "Published just now"}}');
    await tester.pump();

    expect(find.text('Published just now'), findsOneWidget);

    service.apply('{}');
    await tester.pump();

    expect(find.text('The app\'s own'), findsOneWidget);
  });
}
