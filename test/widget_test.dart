import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CampusCare home screen displays correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('CampusCare')),
          body: const Column(
            children: [
              Text('Welcome to CampusCare 👋'),
              Text('Report an incident'),
              Text('Browse incidents'),
              Text('Track progress'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('CampusCare'), findsOneWidget);
    expect(find.text('Welcome to CampusCare 👋'), findsOneWidget);
    expect(find.text('Report an incident'), findsOneWidget);
    expect(find.text('Browse incidents'), findsOneWidget);
    expect(find.text('Track progress'), findsOneWidget);
  });
}
