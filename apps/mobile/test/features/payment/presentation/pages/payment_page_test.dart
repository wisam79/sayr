import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:sayr_mobile/features/payment/presentation/bloc/payment_event.dart';
import 'package:sayr_mobile/features/payment/presentation/bloc/payment_state.dart';
import 'package:sayr_mobile/features/payment/presentation/pages/payment_page.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

class MockPaymentBloc extends MockBloc<PaymentEvent, PaymentState>
    implements PaymentBloc {}

void main() {
  late MockPaymentBloc mockPaymentBloc;

  setUpAll(() {
    registerFallbackValue(const RouteId('fallback'));
    registerFallbackValue(const PaymentReset());
  });

  setUp(() {
    mockPaymentBloc = MockPaymentBloc();
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: BlocProvider<PaymentBloc>.value(
        value: mockPaymentBloc,
        child: child,
      ),
    );
  }

  testWidgets('renders loader when state is PaymentLoading', (tester) async {
    when(() => mockPaymentBloc.state).thenReturn(const PaymentLoading(message: 'Generating transaction...'));

    await tester.pumpWidget(
      wrap(
        const PaymentPage(
          routeId: RouteId('route-1'),
          amount: 5000,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Generating transaction...'), findsOneWidget);
  });

  testWidgets('renders Zain Cash options and Zain Cash button when state is PaymentUrlReady', (tester) async {
    when(() => mockPaymentBloc.state).thenReturn(
      const PaymentUrlReady(
        paymentId: 'pay-123',
        paymentUrl: 'https://test.zaincash.iq/transaction/pay-123',
        amount: 5000,
        currency: 'IQD',
      ),
    );

    await tester.pumpWidget(
      wrap(
        const PaymentPage(
          routeId: RouteId('route-1'),
          amount: 5000,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Pay via Zain Cash'), findsOneWidget);
    expect(find.text('Amount: 5000 IQD'), findsOneWidget);
    expect(find.byType(PrimaryButton), findsOneWidget);
    expect(find.text('Open Zain Cash'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('renders awaiting completion message when state is PaymentAwaitingCompletion', (tester) async {
    when(() => mockPaymentBloc.state).thenReturn(const PaymentAwaitingCompletion(paymentId: 'pay-123'));

    await tester.pumpWidget(
      wrap(
        const PaymentPage(
          routeId: RouteId('route-1'),
          amount: 5000,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Awaiting payment confirmation...'), findsOneWidget);
    expect(find.text('Complete the payment in Zain Cash app then return here'), findsOneWidget);
  });

  testWidgets('renders failure state with retry and help buttons when state is PaymentFailed', (tester) async {
    when(() => mockPaymentBloc.state).thenReturn(
      const PaymentFailed(
        failure: ServerFailure(message: 'Zain Cash API Error'),
      ),
    );

    await tester.pumpWidget(
      wrap(
        const PaymentPage(
          routeId: RouteId('route-1'),
          amount: 5000,
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Payment failed'), findsOneWidget);
    expect(find.text('Zain Cash API Error'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);
  });
}
