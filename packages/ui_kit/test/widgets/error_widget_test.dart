import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

void main() {
  group('AppErrorWidget Widget Tests', () {
    testWidgets('renders message and default title',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppErrorWidget(
              message: 'Failed to load data',
              title: 'Error',
              retryLabel: 'Retry',
            ),
          ),
        ),
      );

      expect(find.text('Failed to load data'), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('renders custom title and retry button with label',
        (WidgetTester tester) async {
      var isRetried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorWidget(
              message: 'Database error',
              title: 'Custom Error Title',
              retryLabel: 'Try Again',
              onRetry: () {
                isRetried = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Custom Error Title'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(isRetried, isTrue);
    });
  });
}
