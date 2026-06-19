import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/complete_profile_cubit.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuth;
  late CompleteProfileCubit cubit;

  setUp(() {
    mockAuth = MockAuthRepository();
    cubit = CompleteProfileCubit(authRepository: mockAuth);
  });

  tearDown(() => cubit.close());

  group('CompleteProfileCubit', () {
    test('initial state has correct defaults', () {
      expect(cubit.state.institutions, isEmpty);
      expect(cubit.state.selectedInstitutionId, isNull);
      expect(cubit.state.phone, '');
      expect(cubit.state.isLoading, false);
      expect(cubit.state.isLoadingInstitutions, true);
      expect(cubit.state.errorMessage, isNull);
    });

    blocTest<CompleteProfileCubit, CompleteProfileState>(
      'loadInstitutions emits institutions on success',
      build: () {
        when(() => mockAuth.getInstitutions()).thenAnswer(
          (_) async => const Right([
            (id: 'inst-1', name: 'جامعة بغداد', city: 'بغداد'),
            (id: 'inst-2', name: 'جامعة البصرة', city: 'البصرة'),
          ]),
        );
        return CompleteProfileCubit(authRepository: mockAuth);
      },
      act: (cubit) => cubit.loadInstitutions(),
      expect: () => [
        isA<CompleteProfileState>().having(
          (s) => s.isLoadingInstitutions,
          'isLoadingInstitutions',
          true,
        ),
        isA<CompleteProfileState>()
            .having(
              (s) => s.isLoadingInstitutions,
              'isLoadingInstitutions',
              false,
            )
            .having(
              (s) => s.institutions.length,
              'institutions count',
              2,
            ),
      ],
    );

    blocTest<CompleteProfileCubit, CompleteProfileState>(
      'loadInstitutions emits error on failure',
      build: () {
        when(() => mockAuth.getInstitutions()).thenAnswer(
          (_) async => const Left(
            ServerFailure(message: 'Connection failed'),
          ),
        );
        return CompleteProfileCubit(authRepository: mockAuth);
      },
      act: (cubit) => cubit.loadInstitutions(),
      expect: () => [
        isA<CompleteProfileState>().having(
          (s) => s.isLoadingInstitutions,
          'isLoadingInstitutions',
          true,
        ),
        isA<CompleteProfileState>()
            .having(
              (s) => s.isLoadingInstitutions,
              'isLoadingInstitutions',
              false,
            )
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Connection failed',
            ),
      ],
    );

    blocTest<CompleteProfileCubit, CompleteProfileState>(
      'phoneChanged updates phone and clears error',
      build: () => CompleteProfileCubit(authRepository: mockAuth),
      seed: () => const CompleteProfileState(errorMessage: 'old error'),
      act: (cubit) => cubit.phoneChanged('07901234567'),
      expect: () => [
        isA<CompleteProfileState>()
            .having((s) => s.phone, 'phone', '07901234567')
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
    );

    blocTest<CompleteProfileCubit, CompleteProfileState>(
      'institutionChanged updates selectedInstitutionId and clears error',
      build: () => CompleteProfileCubit(authRepository: mockAuth),
      seed: () => const CompleteProfileState(errorMessage: 'err'),
      act: (cubit) => cubit.institutionChanged('inst-1'),
      expect: () => [
        isA<CompleteProfileState>()
            .having(
              (s) => s.selectedInstitutionId,
              'selectedInstitutionId',
              'inst-1',
            )
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
    );

    group('isValid', () {
      test(
          'returns true when phone >= 11 chars, starts with 07, and institution selected',
          () {
        const state = CompleteProfileState(
          phone: '07901234567',
          selectedInstitutionId: 'inst-1',
        );
        expect(state.isValid, isTrue);
      });

      test('returns false when phone is too short', () {
        const state = CompleteProfileState(
          phone: '0790123456',
          selectedInstitutionId: 'inst-1',
        );
        expect(state.isValid, isFalse);
      });

      test('returns false when phone does not start with 07', () {
        const state = CompleteProfileState(
          phone: '09901234567',
          selectedInstitutionId: 'inst-1',
        );
        expect(state.isValid, isFalse);
      });

      test('returns false when institution is null', () {
        const state = CompleteProfileState(
          phone: '07901234567',
        );
        expect(state.isValid, isFalse);
      });

      test('returns false when all empty', () {
        const state = CompleteProfileState();
        expect(state.isValid, isFalse);
      });
    });
  });
}
