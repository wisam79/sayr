import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_mobile/features/home/presentation/widgets/safety_tips_sheet.dart';
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
      home: child,
    );
  }

  testWidgets(
      'showSafetyTipsBottomSheet opens sheet and renders all safety tips',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showSafetyTipsBottomSheet(context),
                  child: const Text('Show Sheet'),
                ),
              ),
            );
          },
        ),
      ),
    );

    // Tap to show bottom sheet
    await tester.tap(find.text('Show Sheet'));
    await tester.pumpAndSettle(); // wait for slide-up animation

    // Verify title and safety tip rows are present
    expect(find.text('نصائح السلامة في سير'), findsOneWidget);
    expect(
      find.text(
        'احرص على إبقاء هاتفك قريباً وتفعيل البلوتوث للصعود التلقائي إلى الحافلة.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('يرجى الانتظار حتى تتوقف الحافلة تماماً قبل الصعود أو النزول.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'استخدم زر الاستغاثة (SOS) في صفحة التتبع إذا شعرت بعدم الأمان في أي وقت.',
      ),
      findsOneWidget,
    );
  });
}
