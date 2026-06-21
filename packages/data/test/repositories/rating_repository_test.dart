import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';
import 'package:sayr_data/src/models/rating_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:talker_flutter/talker_flutter.dart';

class MockRemoteDatasource extends Mock implements RemoteDatasource {}

class MockUser extends Mock implements supabase.User {}

void main() {
  late RatingRepositoryImpl repository;
  late MockRemoteDatasource mockRemote;

  final mockUser = MockUser();

  setUp(() {
    mockRemote = MockRemoteDatasource();
    when(() => mockUser.id).thenReturn('user-123');
    registerFallbackValue(const TripId('trip-1'));

    repository = RatingRepositoryImpl(
      remoteDatasource: mockRemote,
      talker: Talker(),
    );
  });

  const tripId = TripId('trip-1');
  const driverId = DriverId('driver-1');

  group('RatingRepositoryImpl', () {
    group('submitRating', () {
      test('returns Rating on success', () async {
        when(() => mockRemote.currentUser).thenReturn(mockUser);
        when(
          () => mockRemote.submitRating(
            tripId: 'trip-1',
            driverId: 'driver-1',
            studentId: 'user-123',
            rating: 5,
            comment: any(named: 'comment'),
          ),
        ).thenAnswer(
          (_) async => RatingModel.fromJson(const {
            'id': 'rating-1',
            'trip_id': 'trip-1',
            'student_id': 'user-123',
            'driver_id': 'driver-1',
            'rating': 5,
            'created_at': '2026-06-18T10:00:00Z',
            'comment': 'Great ride',
          }),
        );

        final result = await repository.submitRating(
          tripId: tripId,
          driverId: driverId,
          rating: 5,
          comment: 'Great ride',
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('expected Right'),
          (rating) {
            expect(rating.id.value, 'rating-1');
            expect(rating.rating, 5);
            expect(rating.comment, 'Great ride');
          },
        );
        verify(
          () => mockRemote.submitRating(
            tripId: 'trip-1',
            driverId: 'driver-1',
            studentId: 'user-123',
            rating: 5,
            comment: 'Great ride',
          ),
        ).called(1);
      });

      test('returns UnauthorizedFailure when no current user', () async {
        when(() => mockRemote.currentUser).thenReturn(null);

        final result = await repository.submitRating(
          tripId: tripId,
          driverId: driverId,
          rating: 4,
        );

        expect(result.isLeft(), isTrue);
        expect(
          result.fold((f) => f, (_) => null),
          isA<UnauthorizedFailure>(),
        );
        verifyNever(
          () => mockRemote.submitRating(
            tripId: any(named: 'tripId'),
            driverId: any(named: 'driverId'),
            studentId: any(named: 'studentId'),
            rating: any(named: 'rating'),
            comment: any(named: 'comment'),
          ),
        );
      });

      test('returns Failure when datasource throws', () async {
        when(() => mockRemote.currentUser).thenReturn(mockUser);
        when(
          () => mockRemote.submitRating(
            tripId: 'trip-1',
            driverId: 'driver-1',
            studentId: 'user-123',
            rating: 4,
            comment: any(named: 'comment'),
          ),
        ).thenThrow(Exception('network down'));

        final result = await repository.submitRating(
          tripId: tripId,
          driverId: driverId,
          rating: 4,
        );

        expect(result.isLeft(), isTrue);
      });
    });

    group('getTripRating', () {
      test('returns Rating when one exists', () async {
        when(() => mockRemote.currentUser).thenReturn(mockUser);
        when(
          () => mockRemote.getTripRating(
            tripId: 'trip-1',
            studentId: 'user-123',
          ),
        ).thenAnswer(
          (_) async => RatingModel.fromJson(const {
            'id': 'rating-1',
            'trip_id': 'trip-1',
            'student_id': 'user-123',
            'driver_id': 'driver-1',
            'rating': 3,
            'created_at': '2026-06-18T10:00:00Z',
          }),
        );

        final result = await repository.getTripRating(tripId);

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('expected Right'),
          (rating) {
            expect(rating, isNotNull);
            expect(rating!.rating, 3);
            expect(rating.comment, isNull);
          },
        );
      });

      test('returns null when no rating exists', () async {
        when(() => mockRemote.currentUser).thenReturn(mockUser);
        when(
          () => mockRemote.getTripRating(
            tripId: 'trip-1',
            studentId: 'user-123',
          ),
        ).thenAnswer((_) async => null);

        final result = await repository.getTripRating(tripId);

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('expected Right'),
          (rating) => expect(rating, isNull),
        );
      });

      test('returns UnauthorizedFailure when no current user', () async {
        when(() => mockRemote.currentUser).thenReturn(null);

        final result = await repository.getTripRating(tripId);

        expect(result.isLeft(), isTrue);
        expect(
          result.fold((f) => f, (_) => null),
          isA<UnauthorizedFailure>(),
        );
      });
    });
  });
}
