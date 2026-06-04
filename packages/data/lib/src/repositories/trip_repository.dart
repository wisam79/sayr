import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';

import '../models/payment_info.dart';
import '../supabase/supabase_client.dart';

/// Repository for trip operations.
@lazySingleton
class TripRepository {
  TripRepository({SayrSupabase? supabase})
      : _supabase = supabase ?? SayrSupabase.instance;

  final SayrSupabase _supabase;

  /// Get all active trips for the current user (student view).
  Future<Either<Failure, List<Trip>>> getActiveTrips() async {
    try {
      final response = await _supabase.client.from('trips').select().inFilter(
          'status', [
        'scheduled',
        'driver_waiting',
        'in_transit'
      ]).order('scheduled_at', ascending: true);

      final trips = (response as List)
          .cast<Map<String, dynamic>>()
          .map(_fromJson)
          .toList();
      return Right<Failure, List<Trip>>(trips);
    } catch (e) {
      return Left<Failure, List<Trip>>(ServerFailure(message: e.toString()));
    }
  }

  /// Subscribe to a trip's status changes via realtime.
  Stream<Trip> watchTrip(TripId tripId) {
    return _supabase.client
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('id', tripId.value)
        .map((rows) {
          if (rows.isEmpty) {
            throw StateError('Trip $tripId not found');
          }
          return _fromJson(rows.first);
        });
  }

  /// Get a trip by ID.
  Future<Either<Failure, Trip>> getById(TripId id) async {
    try {
      final response = await _supabase.client
          .from('trips')
          .select()
          .eq('id', id.value)
          .maybeSingle();

      if (response == null) {
        return const Left<Failure, Trip>(NotFoundFailure(resource: 'trip'));
      }

      return Right<Failure, Trip>(_fromJson(response));
    } catch (e) {
      return Left<Failure, Trip>(ServerFailure(message: e.toString()));
    }
  }

  /// Update trip status (via RPC - validates FSM transitions).
  Future<Either<Failure, Trip>> updateStatus({
    required TripId tripId,
    required TripEvent event,
    Coordinates? location,
  }) async {
    final current = await getById(tripId);
    return current.fold<Future<Either<Failure, Trip>>>(
      (Failure failure) async => Left<Failure, Trip>(failure),
      (Trip trip) async {
        final newStatus = TripStateMachine.transition(trip.status, event);
        if (newStatus == null) {
          return Left<Failure, Trip>(
            InvalidStateTransitionFailure(
              from: trip.status.name,
              event: event.name,
            ),
          );
        }
        try {
          final response = await _supabase.client.rpc<Map<String, dynamic>>(
            'update_trip_status',
            params: {
              'p_trip_id': tripId.value,
              'p_new_status': _statusToDb(newStatus),
              'p_lat': location?.latitude,
              'p_lng': location?.longitude,
            },
          );
          return Right<Failure, Trip>(_fromJson(response));
        } catch (e) {
          return Left<Failure, Trip>(ServerFailure(message: e.toString()));
        }
      },
    );
  }

  /// Update only location (no status change).
  Future<Either<Failure, Unit>> updateLocation({
    required TripId tripId,
    required double lat,
    required double lng,
  }) async {
    try {
      await _supabase.client.rpc<void>(
        'update_trip_location',
        params: {
          'p_trip_id': tripId.value,
          'p_lat': lat,
          'p_lng': lng,
        },
      );
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(ServerFailure(message: e.toString()));
    }
  }

  /// Bulk update locations (for offline sync).
  Future<Either<Failure, Unit>> bulkUpdateLocations(
    List<
            ({
              TripId tripId,
              double lat,
              double lng,
            })>
        locations,
  ) async {
    try {
      final locationsJson = locations
          .map((l) => {
                'trip_id': l.tripId.value,
                'lat': l.lat,
                'lng': l.lng,
              })
          .toList();

      await _supabase.client.rpc<void>(
        'bulk_update_trip_locations',
        params: {'p_locations': locationsJson},
      );
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(ServerFailure(message: e.toString()));
    }
  }

  /// Create a Zain Cash payment.
  Future<Either<Failure, PaymentInfo>> createPayment({
    required RouteId routeId,
    required int amount,
    required String currency,
    required String method,
  }) async {
    try {
      final response = await _supabase.client.rpc<Map<String, dynamic>>(
        'create_payment',
        params: {
          'p_route_id': routeId.value,
          'p_amount': amount,
          'p_currency': currency,
          'p_method': method,
        },
      );
      return Right<Failure, PaymentInfo>(PaymentInfo.fromJson(response));
    } catch (e) {
      return Left<Failure, PaymentInfo>(ServerFailure(message: e.toString()));
    }
  }

  /// Get payment status.
  Future<Either<Failure, PaymentInfo>> getPaymentStatus(
    String paymentId,
  ) async {
    try {
      final response = await _supabase.client
          .from('payments')
          .select()
          .eq('id', paymentId)
          .maybeSingle();

      if (response == null) {
        return const Left<Failure, PaymentInfo>(
          NotFoundFailure(resource: 'payment'),
        );
      }

      return Right<Failure, PaymentInfo>(PaymentInfo.fromJson(response));
    } catch (e) {
      return Left<Failure, PaymentInfo>(ServerFailure(message: e.toString()));
    }
  }

  Trip _fromJson(Map<String, dynamic> json) {
    return Trip(
      id: TripId(json['id'] as String),
      routeId: RouteId(json['route_id'] as String),
      driverId: DriverId(json['driver_id'] as String),
      status: TripStatus.fromString(json['status'] as String),
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      lastLocation: (json['last_lat'] != null && json['last_lng'] != null)
          ? Coordinates(
              latitude: (json['last_lat'] as num).toDouble(),
              longitude: (json['last_lng'] as num).toDouble(),
            )
          : null,
    );
  }

  String _statusToDb(TripStatus status) {
    switch (status) {
      case TripStatus.scheduled:
        return 'scheduled';
      case TripStatus.driverWaiting:
        return 'driver_waiting';
      case TripStatus.inTransit:
        return 'in_transit';
      case TripStatus.completed:
        return 'completed';
      case TripStatus.absent:
        return 'absent';
      case TripStatus.cancelled:
        return 'cancelled';
    }
  }
}
