import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class MockRemoteDatasource extends Mock implements RemoteDatasource {}

class MockLocalDatasource extends Mock implements LocalDatasource {}

class MockUser extends Mock implements supabase.User {}

class MockAuthResponse extends Mock implements supabase.AuthResponse {}

void main() {
  late AuthRepositoryImpl repository;
  late MockRemoteDatasource mockRemote;
  late MockLocalDatasource mockLocal;

  setUp(() {
    mockRemote = MockRemoteDatasource();
    mockLocal = MockLocalDatasource();

    // Stub local datasource methods to avoid missing stub exceptions
    when(() => mockLocal.setUserId(any())).thenAnswer((_) async => {});
    when(() => mockLocal.clearSecureStorage()).thenAnswer((_) async => {});
    when(() => mockLocal.clearCachedTrips()).thenAnswer((_) async => {});

    repository = AuthRepositoryImpl(
      remoteDatasource: mockRemote,
      localDatasource: mockLocal,
    );
  });

  group('AuthRepositoryImpl', () {
    group('currentUser', () {
      test('returns null when no user is signed in', () {
        when(() => mockRemote.currentUser).thenReturn(null);

        final user = repository.currentUser;

        expect(user, isNull);
        verify(() => mockRemote.currentUser).called(1);
      });

      test('returns User when user is signed in', () {
        final mockUser = MockUser();
        when(() => mockUser.id).thenReturn('user-123');
        when(() => mockUser.email).thenReturn('test@example.com');
        when(() => mockUser.appMetadata).thenReturn({'role': 'student'});
        when(() => mockUser.userMetadata)
            .thenReturn({'full_name': 'Test User', 'phone': '07700000000'});
        when(() => mockRemote.currentUser).thenReturn(mockUser);

        final user = repository.currentUser;

        expect(user, isNotNull);
        expect(user!.id, const UserId('user-123'));
        expect(user.email, 'test@example.com');
        expect(user.role, UserRole.student);
        expect(user.fullName, 'Test User');
        expect(user.phone, '07700000000');
        verify(() => mockRemote.currentUser).called(1);
      });

      test('defaults to student role when role not in app_metadata', () {
        final mockUser = MockUser();
        when(() => mockUser.id).thenReturn('user-456');
        when(() => mockUser.email).thenReturn('no-role@example.com');
        when(() => mockUser.appMetadata).thenReturn({});
        when(() => mockUser.userMetadata).thenReturn(null);
        when(() => mockRemote.currentUser).thenReturn(mockUser);

        final user = repository.currentUser;

        expect(user!.role, UserRole.student);
        verify(() => mockRemote.currentUser).called(1);
      });
    });

    group('signInWithPassword', () {
      test('returns User on success', () async {
        final mockUser = MockUser();
        when(() => mockUser.id).thenReturn('user-123');
        when(() => mockUser.email).thenReturn('test@example.com');
        when(() => mockUser.appMetadata).thenReturn({'role': 'driver'});
        when(() => mockUser.userMetadata)
            .thenReturn({'full_name': 'Driver User'});

        final mockResponse = MockAuthResponse();
        when(() => mockResponse.user).thenReturn(mockUser);

        when(
          () => mockRemote.signInWithPassword(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).thenAnswer((_) async => mockResponse);

        final result = await repository.signInWithPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (user) {
            expect(user.id, const UserId('user-123'));
            expect(user.role, UserRole.driver);
            expect(user.fullName, 'Driver User');
          },
        );
        verify(() => mockLocal.setUserId('user-123')).called(1);
      });

      test('returns UnauthorizedFailure when user is null in response',
          () async {
        final mockResponse = MockAuthResponse();
        when(() => mockResponse.user).thenReturn(null);

        when(
          () => mockRemote.signInWithPassword(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).thenAnswer((_) async => mockResponse);

        final result = await repository.signInWithPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<UnauthorizedFailure>());
          },
          (user) => fail('should fail'),
        );
        verifyNever(() => mockLocal.setUserId(any()));
      });

      test('returns UnauthorizedFailure on AuthException', () async {
        when(
          () => mockRemote.signInWithPassword(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).thenThrow(const supabase.AuthException('invalid credentials'));

        final result = await repository.signInWithPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<UnauthorizedFailure>());
            expect(
              (failure as UnauthorizedFailure).message,
              'invalid credentials',
            );
          },
          (user) => fail('should fail'),
        );
        verifyNever(() => mockLocal.setUserId(any()));
      });

      test('returns UnknownFailure on general exception', () async {
        when(
          () => mockRemote.signInWithPassword(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).thenThrow(Exception('Network Error'));

        final result = await repository.signInWithPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<UnknownFailure>());
            expect(
              (failure as UnknownFailure).message,
              contains('Network Error'),
            );
          },
          (_) => fail('should fail'),
        );
        verifyNever(() => mockLocal.setUserId(any()));
      });
    });

    group('signUp', () {
      test('returns User on success', () async {
        final mockUser = MockUser();
        when(() => mockUser.id).thenReturn('user-123');
        when(() => mockUser.email).thenReturn('new@example.com');
        when(() => mockUser.appMetadata).thenReturn({'role': 'student'});
        when(() => mockUser.userMetadata)
            .thenReturn({'full_name': 'New Student'});

        final mockResponse = MockAuthResponse();
        when(() => mockResponse.user).thenReturn(mockUser);

        when(
          () => mockRemote.signUp(
            email: 'new@example.com',
            password: 'password123',
            fullName: 'New Student',
            phone: '07712345678',
          ),
        ).thenAnswer((_) async => mockResponse);

        final result = await repository.signUp(
          email: 'new@example.com',
          password: 'password123',
          fullName: 'New Student',
          phone: '07712345678',
        );

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (user) {
            expect(user.id, const UserId('user-123'));
            expect(user.email, 'new@example.com');
          },
        );
        verify(() => mockLocal.setUserId('user-123')).called(1);
      });

      test('returns ValidationFailure when user is null in response', () async {
        final mockResponse = MockAuthResponse();
        when(() => mockResponse.user).thenReturn(null);

        when(
          () => mockRemote.signUp(
            email: 'new@example.com',
            password: 'password123',
            fullName: 'New Student',
          ),
        ).thenAnswer((_) async => mockResponse);

        final result = await repository.signUp(
          email: 'new@example.com',
          password: 'password123',
          fullName: 'New Student',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('should fail'),
        );
        verifyNever(() => mockLocal.setUserId(any()));
      });

      test('returns ValidationFailure on AuthException', () async {
        when(
          () => mockRemote.signUp(
            email: 'new@example.com',
            password: 'password123',
            fullName: 'New Student',
          ),
        ).thenThrow(const supabase.AuthException('weak password'));

        final result = await repository.signUp(
          email: 'new@example.com',
          password: 'password123',
          fullName: 'New Student',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).message, 'weak password');
          },
          (user) => fail('should fail'),
        );
        verifyNever(() => mockLocal.setUserId(any()));
      });

      test('returns UnknownFailure on general exception', () async {
        when(
          () => mockRemote.signUp(
            email: 'new@example.com',
            password: 'password123',
            fullName: 'New Student',
          ),
        ).thenThrow(Exception('Server crash'));

        final result = await repository.signUp(
          email: 'new@example.com',
          password: 'password123',
          fullName: 'New Student',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<UnknownFailure>());
            expect(
              (failure as UnknownFailure).message,
              contains('Server crash'),
            );
          },
          (_) => fail('should fail'),
        );
        verifyNever(() => mockLocal.setUserId(any()));
      });
    });

    group('signInWithGoogle', () {
      test(
          'returns Right(unit) on true response and saves userId if user is signed in',
          () async {
        final mockUser = MockUser();
        when(() => mockUser.id).thenReturn('google-user-123');
        when(() => mockRemote.currentUser).thenReturn(mockUser);
        when(() => mockRemote.signInWithGoogle()).thenAnswer((_) async => true);

        final result = await repository.signInWithGoogle();

        expect(result.isRight(), true);
        verify(() => mockRemote.signInWithGoogle()).called(1);
        verify(() => mockLocal.setUserId('google-user-123')).called(1);
      });

      test('returns Right(unit) on true response with no current user',
          () async {
        when(() => mockRemote.currentUser).thenReturn(null);
        when(() => mockRemote.signInWithGoogle()).thenAnswer((_) async => true);

        final result = await repository.signInWithGoogle();

        expect(result.isRight(), true);
        verify(() => mockRemote.signInWithGoogle()).called(1);
        verifyNever(() => mockLocal.setUserId(any()));
      });

      test('returns Left(UnauthorizedFailure) on false response', () async {
        when(() => mockRemote.signInWithGoogle())
            .thenAnswer((_) async => false);

        final result = await repository.signInWithGoogle();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<UnauthorizedFailure>()),
          (_) => fail('should fail'),
        );
        verifyNever(() => mockLocal.setUserId(any()));
      });

      test('returns Left(UnauthorizedFailure) on AuthException', () async {
        when(() => mockRemote.signInWithGoogle()).thenThrow(
          const supabase.AuthException('Google sign in cancelled'),
        );

        final result = await repository.signInWithGoogle();

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<UnauthorizedFailure>());
            expect(
              (failure as UnauthorizedFailure).message,
              'Google sign in cancelled',
            );
          },
          (_) => fail('should fail'),
        );
        verifyNever(() => mockLocal.setUserId(any()));
      });

      test('returns Left(UnknownFailure) on general exception', () async {
        when(() => mockRemote.signInWithGoogle())
            .thenThrow(Exception('Fatal error'));

        final result = await repository.signInWithGoogle();

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<UnknownFailure>());
            expect(
              (failure as UnknownFailure).message,
              contains('Fatal error'),
            );
          },
          (_) => fail('should fail'),
        );
        verifyNever(() => mockLocal.setUserId(any()));
      });
    });

    group('signOut', () {
      test('calls signOut on remote datasource and clears local storage',
          () async {
        when(() => mockRemote.signOut()).thenAnswer((_) async {});

        await repository.signOut();

        verify(() => mockRemote.signOut()).called(1);
        verify(() => mockLocal.clearSecureStorage()).called(1);
        verify(() => mockLocal.clearCachedTrips()).called(1);
      });
    });

    group('sendPasswordResetEmail', () {
      test('returns Right(unit) when remote succeeds', () async {
        when(() => mockRemote.sendPasswordResetEmail('test@example.com'))
            .thenAnswer((_) async {});

        final result =
            await repository.sendPasswordResetEmail('test@example.com');

        expect(result.isRight(), true);
        verify(() => mockRemote.sendPasswordResetEmail('test@example.com'))
            .called(1);
      });

      test('returns ValidationFailure on AuthException', () async {
        when(() => mockRemote.sendPasswordResetEmail('bad@example.com'))
            .thenThrow(const supabase.AuthException('invalid email'));

        final result = await repository.sendPasswordResetEmail(
          'bad@example.com',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('updatePassword', () {
      test('returns Right(unit) when remote succeeds', () async {
        when(() => mockRemote.updatePassword('new-password'))
            .thenAnswer((_) async {});

        final result = await repository.updatePassword('new-password');

        expect(result.isRight(), true);
        verify(() => mockRemote.updatePassword('new-password')).called(1);
      });

      test('returns ValidationFailure on AuthException', () async {
        when(() => mockRemote.updatePassword('123'))
            .thenThrow(const supabase.AuthException('weak password'));

        final result = await repository.updatePassword('123');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('authStateChanges', () {
      test('returns stream from remote datasource', () {
        final controller = StreamController<supabase.AuthState>();
        when(() => mockRemote.authStateChanges)
            .thenAnswer((_) => controller.stream);

        final stream = repository.authStateChanges;

        expect(stream, isNotNull);
        verify(() => mockRemote.authStateChanges).called(1);
        controller.close();
      });
    });
  });
}
