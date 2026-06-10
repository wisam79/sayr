import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

void main() {
  group('GreetingCard Widget Tests', () {
    testWidgets('renders title, subtitle, avatarWidget, and badgeWidget',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GreetingCard(
              title: 'Hello User',
              subtitle: 'Welcome to Sayr',
              avatarWidget: CircleAvatar(child: Text('U')),
              badgeWidget: Text('Student Badge'),
            ),
          ),
        ),
      );

      expect(find.text('Hello User'), findsOneWidget);
      expect(find.text('Welcome to Sayr'), findsOneWidget);
      expect(find.text('U'), findsOneWidget);
      expect(find.text('Student Badge'), findsOneWidget);
    });

    testWidgets('renders title, avatarWidget, and badgeWidget without subtitle',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GreetingCard(
              title: 'Hello User',
              subtitle: '',
              avatarWidget: CircleAvatar(child: Text('U')),
              badgeWidget: Text('Student Badge'),
            ),
          ),
        ),
      );

      expect(find.text('Hello User'), findsOneWidget);
      expect(find.text('Welcome to Sayr'), findsNothing);
      expect(find.text('U'), findsOneWidget);
      expect(find.text('Student Badge'), findsOneWidget);
    });
  });
}
