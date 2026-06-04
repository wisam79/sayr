import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

void main() {
  group('AppTextField Widget Tests', () {
    testWidgets('renders label and hint text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextField(
              label: 'Test Label',
              hint: 'Test Hint',
            ),
          ),
        ),
      );

      expect(find.text('Test Label'), findsOneWidget);
      expect(find.text('Test Hint'), findsOneWidget);
    });

    testWidgets('triggers onChanged callback on input',
        (WidgetTester tester) async {
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              label: 'Label',
              onChanged: (String val) {
                changedValue = val;
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'hello');
      expect(changedValue, 'hello');
    });

    testWidgets('renders prefix and suffix icons when provided',
        (WidgetTester tester) async {
      const suffixKey = Key('suffix');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextField(
              label: 'Label',
              prefixIcon: Icons.email,
              suffixIcon: Icon(Icons.check, key: suffixKey),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.email), findsOneWidget);
      expect(find.byKey(suffixKey), findsOneWidget);
    });
  });
}
