import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

void main() {
  group('EmptyState Widget Tests', () {
    testWidgets('renders icon and title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.search,
              title: 'No results',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('No results'), findsOneWidget);
      expect(find.text('Some subtitle'), findsNothing);
    });

    testWidgets('renders subtitle and action widget when provided',
        (WidgetTester tester) async {
      const actionKey = Key('action-btn');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.history,
              title: 'No history',
              subtitle: 'Your history is empty',
              action: ElevatedButton(
                key: actionKey,
                onPressed: () {},
                child: const Text('Refresh'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Your history is empty'), findsOneWidget);
      expect(find.byKey(actionKey), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
    });
  });
}
