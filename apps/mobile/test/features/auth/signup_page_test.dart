import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/pages/signup_page.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';

void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    authBloc = AuthBloc(authRepository: mockRepo);
  });

  tearDown(() => authBloc.close());

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
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: child,
      ),
    );
  }

  testWidgets('SignupPage renders signup form fields', (tester) async {
    await tester.pumpWidget(wrap(const SignupPage()));
    await tester.pump();

    expect(find.byType(TextFormField), findsAtLeast(4));
  });
}

class MockAuthRepository extends Mock implements AuthRepository {}
