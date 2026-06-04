import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

void main() {
  group('SectionHeader Widget Tests', () {
    testWidgets('renders title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Featured Routes',
            ),
          ),
        ),
      );

      expect(find.text('Featured Routes'), findsOneWidget);
    });

    testWidgets('renders action widget when provided',
        (WidgetTester tester) async {
      const btnKey = Key('view-all');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Featured Routes',
              action: TextButton(
                key: btnKey,
                onPressed: () {},
                child: const Text('View All'),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(btnKey), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
    });
  });
}
