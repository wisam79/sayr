import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/widgets/success_subscription_dialog.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ar'),
      home: Scaffold(
        body: child,
      ),
    );
  }

  testWidgets('SuccessSubscriptionDialog renders success message and button, calls onConfirm', (tester) async {
    var confirmed = false;

    await tester.pumpWidget(
      wrap(
        SuccessSubscriptionDialog(
          onConfirm: () {
            confirmed = true;
          },
        ),
      ),
    );

    // Pump to start the animation
    await tester.pump();
    // Pump to complete the animation (800ms duration)
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('تم تفعيل الترخيص بنجاح!'), findsOneWidget);
    expect(find.text('العودة للرئيسية'), findsOneWidget);

    await tester.tap(find.text('العودة للرئيسية'));
    await tester.pump();

    expect(confirmed, isTrue);
  });
}
