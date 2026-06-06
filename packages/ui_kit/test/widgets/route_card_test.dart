import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

void main() {
  group('RouteCard Widget Tests', () {
    testWidgets('renders route details and formatted price',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RouteCard(
              title: 'Karrada - University of Baghdad',
              startLocation: 'Karrada',
              endLocation: 'Jadriyah',
              availableSeats: 5,
              capacity: 20,
              formattedPrice: '15,000 د.ع',
              hasSeats: true,
              availableLabel: 'Available',
              completedLabel: 'Full',
            ),
          ),
        ),
      );

      expect(find.text('Karrada - University of Baghdad'), findsOneWidget);
      expect(find.text('Karrada'), findsOneWidget);
      expect(find.text('Jadriyah'), findsOneWidget);
      expect(find.text('5/20'), findsOneWidget);
      expect(find.text('15,000 د.ع'), findsOneWidget);
    });

    testWidgets('renders available label when seats are available',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RouteCard(
              title: 'Karrada - University of Baghdad',
              startLocation: 'Karrada',
              endLocation: 'Jadriyah',
              availableSeats: 5,
              capacity: 20,
              formattedPrice: '15,000 د.ع',
              hasSeats: true,
              availableLabel: 'Seats Available',
              completedLabel: 'Full',
            ),
          ),
        ),
      );

      expect(find.text('Seats Available'), findsOneWidget);
      expect(find.text('Full'), findsNothing);
    });

    testWidgets('renders full label when no seats are available',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RouteCard(
              title: 'Mansour - University of Technology',
              startLocation: 'Mansour',
              endLocation: 'Sinaa St',
              availableSeats: 0,
              capacity: 15,
              formattedPrice: '12,000 د.ع',
              hasSeats: false,
              availableLabel: 'Available',
              completedLabel: 'Fully Booked',
            ),
          ),
        ),
      );

      expect(find.text('Fully Booked'), findsOneWidget);
      expect(find.text('Available'), findsNothing);
    });

    testWidgets('triggers onTap callback when pressed',
        (WidgetTester tester) async {
      var isTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouteCard(
              title: 'Karrada - University of Baghdad',
              startLocation: 'Karrada',
              endLocation: 'Jadriyah',
              availableSeats: 5,
              capacity: 20,
              formattedPrice: '15,000 د.ع',
              hasSeats: true,
              availableLabel: 'Available',
              completedLabel: 'Full',
              onTap: () {
                isTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(RouteCard));
      await tester.pump();

      expect(isTapped, isTrue);
    });
  });
}
