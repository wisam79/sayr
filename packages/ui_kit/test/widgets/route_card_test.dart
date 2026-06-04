import 'package:flutter/material.dart' hide Route;
import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

void main() {
  group('RouteCard Widget Tests', () {
    const testRoute = Route(
      id: RouteId('route-1'),
      driverId: DriverId('driver-1'),
      title: 'Karrada - University of Baghdad',
      startLocation: 'Karrada',
      endLocation: 'Jadriyah',
      price: Money(15000),
      capacity: 20,
      availableSeats: 5,
      isActive: true,
    );

    const testRouteFull = Route(
      id: RouteId('route-2'),
      driverId: DriverId('driver-1'),
      title: 'Mansour - University of Technology',
      startLocation: 'Mansour',
      endLocation: 'Sinaa St',
      price: Money(12000),
      capacity: 15,
      availableSeats: 0,
      isActive: true,
    );

    testWidgets('renders route details and formatted price',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RouteCard(
              route: testRoute,
            ),
          ),
        ),
      );

      expect(find.text('Karrada - University of Baghdad'), findsOneWidget);
      expect(find.text('Karrada'), findsOneWidget);
      expect(find.text('Jadriyah'), findsOneWidget);
      expect(find.text('5/20'), findsOneWidget);
      // check formatted price: 15,000 د.ع
      expect(find.text('15,000 د.ع'), findsOneWidget);
    });

    testWidgets('renders available label when seats are available',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RouteCard(
              route: testRoute,
              availableLabel: 'Seats Available',
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
              route: testRouteFull,
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
              route: testRoute,
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
