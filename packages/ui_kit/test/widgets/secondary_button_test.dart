import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

void main() {
  group('SecondaryButton Widget Tests', () {
    testWidgets('renders label and triggers onPressed',
        (WidgetTester tester) async {
      var isPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecondaryButton(
              label: 'Cancel',
              onPressed: () {
                isPressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();

      expect(isPressed, isTrue);
    });

    testWidgets('renders loading state and disables onPressed',
        (WidgetTester tester) async {
      var isPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecondaryButton(
              label: 'Cancel',
              isLoading: true,
              onPressed: () {
                isPressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);

      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();

      expect(isPressed, isFalse);
    });

    testWidgets('renders icon when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecondaryButton(
              label: 'Share',
              icon: Icons.share,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Share'), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
    });
  });
}
