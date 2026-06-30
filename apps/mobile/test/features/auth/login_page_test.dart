import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late AuthBloc authBloc;

  const testUser = User(
    id: UserId('user-1'),
    email: 'test@sayr.com',
    role: UserRole.student,
    fullName: 'Test User',
  );

  setUp(() {
    mockRepo = MockAuthRepository();
    when(() => mockRepo.authStateChanges)
        .thenAnswer((_) => const Stream<AuthStatus>.empty());
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

  testWidgets('LoginPage shows title, fields, and action buttons',
      (tester) async {
    await tester.pumpWidget(wrap(const LoginPage()));
    await tester.pump();

    expect(find.text('تسجيل الدخول'), findsWidgets);
    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsOneWidget);
    expect(find.text('نسيت كلمة المرور؟'), findsOneWidget);
    expect(find.text('متابعة باستخدام Google'), findsOneWidget);
  });

  testWidgets('Toggles password visibility when icon tapped', (tester) async {
    await tester.pumpWidget(wrap(const LoginPage()));
    await tester.pump();

    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('Shows validation errors when fields are empty', (tester) async {
    await tester.pumpWidget(wrap(const LoginPage()));
    await tester.pump();

    final loginButton = find.widgetWithText(ElevatedButton, 'تسجيل الدخول');
    expect(loginButton, findsOneWidget);

    await tester.tap(loginButton);
    await tester.pump();

    expect(find.text('البريد مطلوب'), findsOneWidget);

    verifyNever(
      () => mockRepo.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('Dispatches AuthLoginRequested on valid submit', (tester) async {
    when(
      () => mockRepo.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => const Right<Failure, User>(testUser),
    );
    when(() => mockRepo.fetchFullProfile()).thenAnswer(
      (_) async => const Right<Failure, User?>(testUser),
    );

    await tester.pumpWidget(wrap(const LoginPage()));
    await tester.pump();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'test@sayr.com');
    await tester.enterText(fields.at(1), 'password123');
    await tester.pump();

    final loginButton = find.widgetWithText(ElevatedButton, 'تسجيل الدخول');
    await tester.tap(loginButton);
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 100));

    verify(
      () => mockRepo.signInWithPassword(
        email: 'test@sayr.com',
        password: 'password123',
      ),
    ).called(1);
  });
}
