import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class MockRemoteDatasource extends Mock implements RemoteDatasource {}

class MockUser extends Mock implements supabase.User {}

void main() {
  late SubscriptionRepositoryImpl repository;
  late MockRemoteDatasource mockRemote;
  late MockUser mockUser;

  setUp(() {
    mockRemote = MockRemoteDatasource();
    mockUser = MockUser();

    when(() => mockUser.id).thenReturn('student-123');
    when(() => mockRemote.currentUser).thenReturn(mockUser);

    repository = SubscriptionRepositoryImpl(
      remoteDatasource: mockRemote,
    );
  });

  group('SubscriptionRepositoryImpl', () {
    final mockSubJson = {
      'id': 'sub-123',
      'student_id': 'student-123',
      'route_id': 'route-456',
      'start_date': '2026-06-01T00:00:00Z',
      'end_date': '2026-06-30T00:00:00Z',
      'is_active': true,
      'payment_method': 'zaincash',
      'status': 'active',
    };

    group('getMySubscriptions', () {
      test('returns List<Subscription> on success', () async {
        when(() => mockRemote.getMySubscriptions('student-123'))
            .thenAnswer((_) async => [mockSubJson]);

        final result = await repository.getMySubscriptions();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (subs) {
            expect(subs.length, 1);
            expect(subs.first.id, const SubscriptionId('sub-123'));
            expect(subs.first.isActive, true);
          },
        );
      });

      test('returns UnauthorizedFailure when user is null', () async {
        when(() => mockRemote.currentUser).thenReturn(null);

        final result = await repository.getMySubscriptions();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<UnauthorizedFailure>()),
          (_) => fail('should fail'),
        );
      });

      test('returns ServerFailure when remote throws exception', () async {
        when(() => mockRemote.getMySubscriptions('student-123'))
            .thenThrow(Exception('DB Error'));

        final result = await repository.getMySubscriptions();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('getActiveSubscriptions', () {
      test('returns active subscriptions that are not expired', () async {
        final mockSubsList = [
          mockSubJson,
          {
            ...mockSubJson,
            'id': 'sub-expired',
            'end_date': '2026-05-01T00:00:00Z', // Expired
          },
          {
            ...mockSubJson,
            'id': 'sub-inactive',
            'status': 'cancelled', // Inactive
          }
        ];

        when(() => mockRemote.getMySubscriptions('student-123'))
            .thenAnswer((_) async => mockSubsList);

        final result = await repository.getActiveSubscriptions();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (subs) {
            expect(subs.length, 1);
            expect(subs.first.id, const SubscriptionId('sub-123'));
          },
        );
      });
    });

    group('cancel', () {
      test('calls cancelSubscription on remote datasource', () async {
        when(() => mockRemote.cancelSubscription('sub-123'))
            .thenAnswer((_) async {});

        final result = await repository.cancel(const SubscriptionId('sub-123'));

        expect(result.isRight(), true);
        verify(() => mockRemote.cancelSubscription('sub-123')).called(1);
      });

      test('returns ServerFailure when remote throws exception', () async {
        when(() => mockRemote.cancelSubscription('sub-123'))
            .thenThrow(Exception('Network timeout'));

        final result = await repository.cancel(const SubscriptionId('sub-123'));

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('activateLicense', () {
      test('returns SubscriptionId on successful activation', () async {
        when(() => mockRemote.activateLicense('A1B2C3D4'))
            .thenAnswer((_) async => 'sub-activated');

        final result =
            await repository.activateLicense(LicenseCode('A1B2C3D4'));

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (subId) => expect(subId, const SubscriptionId('sub-activated')),
        );
      });

      test('maps rate limit error to RateLimitFailure', () async {
        when(() => mockRemote.activateLicense('A1B2C3D4'))
            .thenThrow(Exception('Too many activation attempts'));

        final result =
            await repository.activateLicense(LicenseCode('A1B2C3D4'));

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<RateLimitFailure>()),
          (_) => fail('should fail'),
        );
      });

      test('maps active subscription error to BusinessRuleFailure', () async {
        when(() => mockRemote.activateLicense('A1B2C3D4'))
            .thenThrow(Exception('already have an active subscription'));

        final result =
            await repository.activateLicense(LicenseCode('A1B2C3D4'));

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<BusinessRuleFailure>());
            expect(
              (failure as BusinessRuleFailure).message,
              contains('لديك اشتراك نشط'),
            );
          },
          (_) => fail('should fail'),
        );
      });

      test('maps license not active error to BusinessRuleFailure', () async {
        when(() => mockRemote.activateLicense('A1B2C3D4'))
            .thenThrow(Exception('license not active'));

        final result =
            await repository.activateLicense(LicenseCode('A1B2C3D4'));

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<BusinessRuleFailure>());
            expect(
              (failure as BusinessRuleFailure).message,
              contains('الترخيص غير مفعّل'),
            );
          },
          (_) => fail('should fail'),
        );
      });

      test('maps license not found error to NotFoundFailure', () async {
        when(() => mockRemote.activateLicense('A1B2C3D4'))
            .thenThrow(Exception('license not found'));

        final result =
            await repository.activateLicense(LicenseCode('A1B2C3D4'));

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('should fail'),
        );
      });

      test('maps general error to ServerFailure', () async {
        when(() => mockRemote.activateLicense('A1B2C3D4'))
            .thenThrow(Exception('Generic server failure'));

        final result =
            await repository.activateLicense(LicenseCode('A1B2C3D4'));

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });
  });
}
