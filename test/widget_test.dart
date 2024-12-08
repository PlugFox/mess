import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Widget', () {
    testWidgets(
      'Pump Widget',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      },
    );
  });
}
