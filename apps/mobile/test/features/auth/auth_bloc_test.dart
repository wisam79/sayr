import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';

import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(UserId('fallback'));
  });

  late MockAuthRepository mockRepo;
  late AuthBloc bloc;

  setUp(() {
    mockRepo = MockAuthRepository();
    bloc = AuthBloc(authRepository: mockRepo);
  });

  tearDown(() => bloc.close());

  const testUser = User(
    id: UserId('user-1'),
    email: 'test@sayr.com',
    role: UserRole.student,
    fullName: 'Test User',
  );

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(bloc.state, isA<AuthInitial>());
    });

    group('AuthCheckRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits AuthAuthenticated when currentUser is not null',
        build: () {
          when(() => mockRepo.currentUser).thenReturn(testUser);
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [isA<AuthAuthenticated>()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits AuthUnauthenticated when currentUser is null',
        build: () {
          when(() => mockRepo.currentUser).thenReturn(null);
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [isA<AuthUnauthenticated>()],
      );
    });

    group('AuthLoginRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [Loading, Authenticated] on login success',
        build: () {
          when(() => mockRepo.signInWithPassword(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer(
            (_) async => const Right<Failure, User>(testUser),
          );
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthLoginRequested(
          email: 'test@sayr.com',
          password: 'password123',
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthAuthenticated>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [Loading, Error] on login failure',
        build: () {
          when(() => mockRepo.signInWithPassword(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer(
            (_) async => const Left<Failure, User>(
              UnauthorizedFailure(message: 'Invalid credentials'),
            ),
          );
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthLoginRequested(
          email: 'test@sayr.com',
          password: 'wrong',
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>(),
        ],
      );
    });

    group('AuthSignupRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [Loading, Authenticated] on signup success',
        build: () {
          when(() => mockRepo.signUp(
                email: any(named: 'email'),
                password: any(named: 'password'),
                fullName: any(named: 'fullName'),
                phone: any(named: 'phone'),
              )).thenAnswer(
            (_) async => const Right<Failure, User>(testUser),
          );
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthSignupRequested(
          email: 'test@sayr.com',
          password: 'password123',
          fullName: 'Test User',
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthAuthenticated>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [Loading, Error] on signup failure',
        build: () {
          when(() => mockRepo.signUp(
                email: any(named: 'email'),
                password: any(named: 'password'),
                fullName: any(named: 'fullName'),
                phone: any(named: 'phone'),
              )).thenAnswer(
            (_) async => const Left<Failure, User>(
              ValidationFailure(message: 'Email already exists'),
            ),
          );
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthSignupRequested(
          email: 'existing@sayr.com',
          password: 'password123',
          fullName: 'Test User',
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>(),
        ],
      );
    });

    group('AuthGoogleSignInRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [Loading, Authenticated] on Google sign-in success with currentUser',
        build: () {
          when(() => mockRepo.signInWithGoogle()).thenAnswer(
            (_) async => const Right<Failure, Unit>(unit),
          );
          when(() => mockRepo.currentUser).thenReturn(testUser);
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthGoogleSignInRequested()),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthAuthenticated>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [Loading, Unauthenticated] on Google sign-in success but currentUser is null',
        build: () {
          when(() => mockRepo.signInWithGoogle()).thenAnswer(
            (_) async => const Right<Failure, Unit>(unit),
          );
          when(() => mockRepo.currentUser).thenReturn(null);
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthGoogleSignInRequested()),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthUnauthenticated>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [Loading, Error] on Google sign-in failure',
        build: () {
          when(() => mockRepo.signInWithGoogle()).thenAnswer(
            (_) async => const Left<Failure, Unit>(
              UnauthorizedFailure(message: 'Google sign-in failed'),
            ),
          );
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthGoogleSignInRequested()),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>(),
        ],
      );
    });

    group('AuthPasswordResetRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [Loading, PasswordResetEmailSent] on success',
        build: () {
          when(() => mockRepo.sendPasswordResetEmail(any())).thenAnswer(
            (_) async => const Right<Failure, Unit>(unit),
          );
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(
          const AuthPasswordResetRequested('test@sayr.com'),
        ),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthPasswordResetEmailSent>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [Loading, Error] on failure',
        build: () {
          when(() => mockRepo.sendPasswordResetEmail(any())).thenAnswer(
            (_) async => const Left<Failure, Unit>(
              ValidationFailure(message: 'invalid email'),
            ),
          );
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(
          const AuthPasswordResetRequested('bad-email'),
        ),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>(),
        ],
      );
    });

    group('AuthPasswordUpdateRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [Loading, PasswordUpdated] on success',
        build: () {
          when(() => mockRepo.updatePassword(any())).thenAnswer(
            (_) async => const Right<Failure, Unit>(unit),
          );
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(
          const AuthPasswordUpdateRequested('new-password'),
        ),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthPasswordUpdated>(),
        ],
        verify: (_) => verify(
          () => mockRepo.updatePassword('new-password'),
        ).called(1),
      );

      blocTest<AuthBloc, AuthState>(
        'emits [Loading, Error] on failure',
        build: () {
          when(() => mockRepo.updatePassword(any())).thenAnswer(
            (_) async => const Left<Failure, Unit>(
              ValidationFailure(message: 'weak password'),
            ),
          );
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(
          const AuthPasswordUpdateRequested('123'),
        ),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>(),
        ],
      );
    });

    group('AuthLogoutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits Unauthenticated after logout',
        build: () {
          when(() => mockRepo.signOut()).thenAnswer((_) async {});
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthLogoutRequested()),
        expect: () => [isA<AuthUnauthenticated>()],
        verify: (_) => verify(() => mockRepo.signOut()).called(1),
      );
    });

    group('AuthUserChanged', () {
      blocTest<AuthBloc, AuthState>(
        'emits Authenticated when user is not null',
        build: () => AuthBloc(authRepository: mockRepo),
        act: (bloc) => bloc.add(const AuthUserChanged(testUser)),
        expect: () => [isA<AuthAuthenticated>()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits Unauthenticated when user is null',
        build: () => AuthBloc(authRepository: mockRepo),
        act: (bloc) => bloc.add(const AuthUserChanged(null)),
        expect: () => [isA<AuthUnauthenticated>()],
      );
    });
  });
}
