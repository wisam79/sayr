import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:talker_flutter/talker_flutter.dart';

class MockRemoteDatasource extends Mock implements RemoteDatasource {}

class MockUser extends Mock implements supabase.User {}

void main() {
  late EmergencyRepositoryImpl repository;
  late MockRemoteDatasource mockRemote;
  late MockUser mockUser;

  setUp(() {
    mockRemote = MockRemoteDatasource();
    mockUser = MockUser();

    when(() => mockUser.id).thenReturn('student-123');
    when(() => mockRemote.currentUser).thenReturn(mockUser);

    repository = EmergencyRepositoryImpl(
      remoteDatasource: mockRemote,
      talker: Talker(),
    );
  });

  group('EmergencyRepositoryImpl', () {
    group('triggerEmergency', () {
      test('returns EmergencyReport on success', () async {
        when(
          () => mockRemote.triggerEmergency(
            tripId: 'trip-1',
            routeId: 'route-1',
            studentId: 'student-123',
            lat: 33,
            lng: 44,
            description: 'SOS Help',
          ),
        ).thenAnswer((_) async => 'report-999');

        final result = await repository.triggerEmergency(
          tripId: const TripId('trip-1'),
          routeId: const RouteId('route-1'),
          location: const Coordinates(latitude: 33, longitude: 44),
          message: 'SOS Help',
        );

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (report) {
            expect(report.id, const EmergencyReportId('report-999'));
            expect(report.userId, const UserId('student-123'));
            expect(report.tripId, const TripId('trip-1'));
            expect(report.location.latitude, 33);
            expect(report.location.longitude, 44);
          },
        );
      });

      test('returns UnauthorizedFailure when not logged in', () async {
        when(() => mockRemote.currentUser).thenReturn(null);

        final result = await repository.triggerEmergency(
          tripId: const TripId('trip-1'),
          routeId: const RouteId('route-1'),
          location: const Coordinates(latitude: 33, longitude: 44),
          message: 'SOS Help',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<UnauthorizedFailure>()),
          (_) => fail('should fail'),
        );
      });

      test('returns ServerFailure when remote datasource throws error',
          () async {
        when(
          () => mockRemote.triggerEmergency(
            tripId: 'trip-1',
            routeId: 'route-1',
            studentId: 'student-123',
            lat: 33,
            lng: 44,
            description: 'SOS Help',
          ),
        ).thenThrow(Exception('Invoke Failed'));

        final result = await repository.triggerEmergency(
          tripId: const TripId('trip-1'),
          routeId: const RouteId('route-1'),
          location: const Coordinates(latitude: 33, longitude: 44),
          message: 'SOS Help',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(
              (failure as ServerFailure).message,
              contains('Invoke Failed'),
            );
          },
          (_) => fail('should fail'),
        );
      });
    });

    group('getActiveReport', () {
      test('returns EmergencyReport when active report exists', () async {
        final mockJson = {
          'id': 'report-123',
          'user_id': 'student-123',
          'trip_id': 'trip-2',
          'latitude': 33.123,
          'longitude': 44.456,
          'status': 'reported',
          'created_at': '2026-06-04T12:00:00Z',
        };

        when(() => mockRemote.getActiveEmergencyReport('student-123'))
            .thenAnswer((_) async => mockJson);

        final result = await repository.getActiveReport();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (report) {
            expect(report, isNotNull);
            expect(report!.id, const EmergencyReportId('report-123'));
            expect(report.isActive, true);
          },
        );
      });

      test('returns null when no active report exists', () async {
        when(() => mockRemote.getActiveEmergencyReport('student-123'))
            .thenAnswer((_) async => null);

        final result = await repository.getActiveReport();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (report) => expect(report, isNull),
        );
      });

      test('returns UnauthorizedFailure when not logged in', () async {
        when(() => mockRemote.currentUser).thenReturn(null);

        final result = await repository.getActiveReport();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<UnauthorizedFailure>()),
          (_) => fail('should fail'),
        );
      });

      test('returns ServerFailure when remote throws exception', () async {
        when(() => mockRemote.getActiveEmergencyReport('student-123'))
            .thenThrow(Exception('Fetch active report failed'));

        final result = await repository.getActiveReport();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('resolveReport', () {
      test('returns Right(unit) on success', () async {
        when(
          () => mockRemote.resolveEmergencyReport(
            id: 'report-123',
            resolvedAt: any(named: 'resolvedAt'),
          ),
        ).thenAnswer((_) async {});

        final result = await repository
            .resolveReport(const EmergencyReportId('report-123'));

        expect(result.isRight(), true);
        verify(
          () => mockRemote.resolveEmergencyReport(
            id: 'report-123',
            resolvedAt: any(named: 'resolvedAt'),
          ),
        ).called(1);
      });

      test(
          'returns ServerFailure when remote resolveEmergencyReport throws exception',
          () async {
        when(
          () => mockRemote.resolveEmergencyReport(
            id: 'report-123',
            resolvedAt: any(named: 'resolvedAt'),
          ),
        ).thenThrow(Exception('Resolve report failed'));

        final result = await repository
            .resolveReport(const EmergencyReportId('report-123'));

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });
  });
}
