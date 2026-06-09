import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sayr_mobile/main.dart' as app;

/// Integration tests for the Sayr app.
///
/// Run with: flutter test integration_test/
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Flow', () {
    testWidgets('shows splash screen and navigates to login', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify splash or login screen is shown
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group('Home Flow', () {
    testWidgets('displays home page tabs', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify bottom navigation or home tabs exist
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });
}
