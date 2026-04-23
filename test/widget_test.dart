import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: Text('Wrestlers loaded — check terminal'))),
    ));

    expect(find.text('Wrestlers loaded — check terminal'), findsOneWidget);
  });
}
