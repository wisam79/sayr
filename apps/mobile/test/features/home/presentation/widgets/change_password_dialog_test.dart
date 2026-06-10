import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart' as core;
import 'package:sayr_mobile/features/home/presentation/widgets/change_password_dialog.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';

class MockAuthRepository extends Mock implements core.AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    GetIt.I.registerFactory<core.AuthRepository>(() => mockAuthRepo);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

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
      home: Scaffold(
        body: dialog,
      ),
    );
  }

  testWidgets('renders password dialog fields', (tester) async {
    await tester.pumpWidget(buildTestWidget(const ChangePasswordDialog()));
    await tester.pump();

    expect(find.text('Change Password'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'New Password'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Confirm New Password'),
      findsOneWidget,
    );
  });

  testWidgets(
      'shows validation errors when passwords do not match or too short',
      (tester) async {
    await tester.pumpWidget(buildTestWidget(const ChangePasswordDialog()));
    await tester.pump();

    final saveButton = find.text('Save Changes');

    // Submit empty fields
    await tester.tap(saveButton);
    await tester.pump();
    expect(find.text('Password is required'), findsOneWidget);

    // Enter short password
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '123');
    await tester.enterText(fields.at(1), '123');
    await tester.pump();
    await tester.tap(saveButton);
    await tester.pump();
    expect(find.text('Password is too short'), findsOneWidget);

    // Enter mismatched passwords
    await tester.enterText(fields.at(0), '123456');
    await tester.enterText(fields.at(1), '1234567');
    await tester.pump();
    await tester.tap(saveButton);
    await tester.pump();
    expect(find.text('Passwords do not match'), findsOneWidget);

    verifyNever(() => mockAuthRepo.updatePassword(any()));
  });

  testWidgets('calls updatePassword on valid input', (tester) async {
    when(() => mockAuthRepo.updatePassword(any())).thenAnswer(
      (_) async => const Right(unit),
    );

    await tester.pumpWidget(buildTestWidget(const ChangePasswordDialog()));
    await tester.pump();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'newpassword123');
    await tester.enterText(fields.at(1), 'newpassword123');
    await tester.pump();

    final saveButton = find.text('Save Changes');
    await tester.tap(saveButton);
    await tester.pump();

    verify(() => mockAuthRepo.updatePassword('newpassword123')).called(1);
  });
}
