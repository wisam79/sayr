import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

void main() {
  group('SayrDialog Widget Tests', () {
    testWidgets('renders title, subtitle, and custom content',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SayrDialog(
              title: 'Confirm Operation',
              subtitle: 'Are you sure you want to proceed?',
              content: Text('Custom dialog body content'),
            ),
          ),
        ),
      );

      expect(find.text('Confirm Operation'), findsOneWidget);
      expect(find.text('Are you sure you want to proceed?'), findsOneWidget);
      expect(find.text('Custom dialog body content'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('renders header icon and custom color',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SayrDialog(
              title: 'Warning Dialog',
              headerIcon: Icons.warning,
              headerIconColor: Colors.red,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning), findsOneWidget);
      final icon = tester.widget<Icon>(find.byIcon(Icons.warning));
      expect(icon.color, Colors.red);
    });

    testWidgets('renders action buttons and triggers callbacks',
        (WidgetTester tester) async {
      var primaryPressed = false;
      var secondaryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SayrDialog(
              title: 'Actions Dialog',
              primaryLabel: 'Yes',
              onPrimaryPressed: () => primaryPressed = true,
              secondaryLabel: 'No',
              onSecondaryPressed: () => secondaryPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);

      await tester.tap(find.text('Yes'));
      await tester.pump();
      expect(primaryPressed, isTrue);

      await tester.tap(find.text('No'));
      await tester.pump();
      expect(secondaryPressed, isTrue);
    });

    testWidgets('shows loading state on buttons when enabled',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SayrDialog(
              title: 'Loading Actions',
              primaryLabel: 'Yes',
              isPrimaryLoading: true,
              secondaryLabel: 'No',
              isSecondaryLoading: true,
            ),
          ),
        ),
      );

      // Loading state hides the labels and shows progress indicators
      expect(find.text('Yes'), findsNothing);
      expect(find.text('No'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
    });
  });
}
