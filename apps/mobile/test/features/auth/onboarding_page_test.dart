import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_mobile/features/auth/presentation/pages/onboarding_page.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';

void main() {
  Widget wrap(Widget child) {
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => child,
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('LOGIN')),
        ),
      ],
    );
    return MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ar'),
      routerConfig: router,
    );
  }

  testWidgets('OnboardingPage shows first page initially with skip button',
      (tester) async {
    await tester.pumpWidget(wrap(const OnboardingPage()));
    await tester.pumpAndSettle();

    expect(find.text('تنقل بسهولة'), findsOneWidget);
    expect(find.text('تخطي'), findsOneWidget);
    expect(find.text('التالي'), findsOneWidget);
  });

  testWidgets('Onboarding navigates to next page on next tap', (tester) async {
    await tester.pumpWidget(wrap(const OnboardingPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    expect(find.text('تتبع مباشر'), findsOneWidget);
  });

  testWidgets('Onboarding shows start label on last page', (tester) async {
    await tester.pumpWidget(wrap(const OnboardingPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    expect(find.text('آمن وموثوق'), findsOneWidget);
    expect(find.text('ابدأ'), findsOneWidget);
  });
}
