import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart' as core;
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:sayr_mobile/features/home/presentation/widgets/edit_profile_dialog.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';

class MockAuthRepository extends Mock implements core.AuthRepository {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockAuthBloc mockAuthBloc;

  setUpAll(() {
    registerFallbackValue(const AuthCheckRequested());
  });

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockAuthBloc = MockAuthBloc();

    GetIt.I.registerFactory<core.AuthRepository>(() => mockAuthRepo);
  });

  tearDown(() async {
    await GetIt.I.reset();
    await mockAuthBloc.close();
  });

  const testUser = core.User(
    id: core.UserId('user-1'),
    email: 'student@sayr.com',
    role: core.UserRole.student,
    fullName: 'Student Name',
    phone: '07701234567',
    institutionId: core.InstitutionId('inst-1'),
  );

  Widget buildTestWidget(Widget dialog) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: Scaffold(
          body: dialog,
        ),
      ),
    );
  }

  testWidgets('renders dialog fields and loads institutions', (tester) async {
    when(() => mockAuthRepo.getInstitutions()).thenAnswer(
      (_) async => const Right([
        (id: 'inst-1', name: 'University 1', city: 'City 1'),
        (id: 'inst-2', name: 'University 2', city: 'City 2'),
      ]),
    );

    await tester
        .pumpWidget(buildTestWidget(const EditProfileDialog(user: testUser)));
    await tester.pump(); // Start fetching
    await tester.pump(); // Finish fetching

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Phone Number'), findsOneWidget);
    expect(find.text('University 1'), findsOneWidget);
  });

  testWidgets(
      'submits update profile on Save tap and triggers AuthCheckRequested',
      (tester) async {
    when(() => mockAuthRepo.getInstitutions()).thenAnswer(
      (_) async => const Right([
        (id: 'inst-1', name: 'University 1', city: 'City 1'),
      ]),
    );

    when(
      () => mockAuthRepo.updateProfile(
        phone: any(named: 'phone'),
        institutionId: any(named: 'institutionId'),
      ),
    ).thenAnswer(
      (_) async => const Right(unit),
    );

    await tester
        .pumpWidget(buildTestWidget(const EditProfileDialog(user: testUser)));
    await tester.pump();
    await tester.pump();

    // Enter new phone number
    final phoneField = find.byType(TextFormField);
    await tester.enterText(phoneField, '07709999999');
    await tester.pump();

    final saveButton = find.text('Save Changes');
    await tester.tap(saveButton);
    await tester.pump();

    verify(
      () => mockAuthRepo.updateProfile(
        phone: '07709999999',
        institutionId: 'inst-1',
      ),
    ).called(1);

    verify(() => mockAuthBloc.add(const AuthCheckRequested())).called(1);
    await tester.pump(const Duration(seconds: 5));
  });
}
