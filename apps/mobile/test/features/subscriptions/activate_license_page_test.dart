import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_bloc.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_event.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_state.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/pages/activate_license_page.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';

class MockSubscriptionsBloc
    extends MockBloc<SubscriptionsEvent, SubscriptionsState>
    implements SubscriptionsBloc {}

void main() {
  late MockSubscriptionsBloc mockBloc;

  setUp(() {
    mockBloc = MockSubscriptionsBloc();
    registerFallbackValue(
      const LicenseActivateRequested('TESTCODE'),
    );
  });

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
      home: BlocProvider<SubscriptionsBloc>.value(
        value: mockBloc,
        child: child,
      ),
    );
  }

  testWidgets('shows license code field and activate button', (tester) async {
    when(() => mockBloc.state).thenReturn(const SubscriptionsInitial());

    await tester.pumpWidget(wrap(const ActivateLicensePage()));
    await tester.pump();

    expect(find.text('تفعيل ترخيص'), findsOneWidget);
    expect(find.text('أدخل كود الترخيص المكون من 8 أحرف'), findsOneWidget);
    expect(find.text('تفعيل'), findsOneWidget);
  });

  testWidgets('shows activating state with loading button', (tester) async {
    when(() => mockBloc.state).thenReturn(const LicenseActivating());

    await tester.pumpWidget(wrap(const ActivateLicensePage()));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error snackbar on SubscriptionsError', (tester) async {
    whenListen(
      mockBloc,
      Stream.fromIterable([
        const SubscriptionsInitial(),
        const SubscriptionsError(ServerFailure(message: 'Invalid code')),
      ]),
      initialState: const SubscriptionsInitial(),
    );

    await tester.pumpWidget(wrap(const ActivateLicensePage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Invalid code'), findsOneWidget);
  });

  testWidgets('trims and uppercases code on submit', (tester) async {
    when(() => mockBloc.state).thenReturn(const SubscriptionsInitial());

    await tester.pumpWidget(wrap(const ActivateLicensePage()));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'test1234');
    await tester.tap(find.text('تفعيل'));

    verify(
      () => mockBloc.add(const LicensePreviewRequested('TEST1234')),
    ).called(1);
  });

  test('ArabicToEnglishDigitsFormatter translates Arabic and Persian digits to English digits', () {
    const formatter = ArabicToEnglishDigitsFormatter();
    
    // Arabic digits
    final resultArabic = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '١٢٣٤٥٦٧٨٩٠'),
    );
    expect(resultArabic.text, '1234567890');

    // Persian/Eastern Arabic digits
    final resultPersian = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '۱۲۳۴۵۶۷۸۹۰'),
    );
    expect(resultPersian.text, '1234567890');

    // Mixed input
    final resultMixed = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: 'ABC١٢٣xyz٤٥'),
    );
    expect(resultMixed.text, 'ABC123xyz45');
  });
}
