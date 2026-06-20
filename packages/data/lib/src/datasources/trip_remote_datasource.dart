import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:sayr_data/src/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Trip lifecycle + payment + driver + rating operations.
///
/// Trip CRUD, live status/location updates, bulk offline sync, payment
/// intents, driver lookups, and rating submission all live here because
/// they share the same domain (the trip itself).
abstract class TripRemoteDatasource {
  /// Returns currently active trips (scheduled, driver_waiting, in_transit).
  Future<List<Map<String, dynamic>>> getActiveTrips();

  /// Creates a new trip via the `create_trip` RPC.
  Future<String> createTrip({
    required String routeId,
    required DateTime scheduledAt,
  });

  /// Realtime stream of a single trip row.
  Stream<List<Map<String, dynamic>>> watchTrip(String tripId);

  /// Fetches a single trip by id.
  Future<Map<String, dynamic>?> getTripById(String id);

  /// Updates a trip's status via the `update_trip_status` RPC.
  Future<Map<String, dynamic>> updateTripStatus({
    required String tripId,
    required String newStatus,
    double? lat,
    double? lng,
  });

  /// Updates a trip's current location via the `update_trip_location` RPC.
  Future<void> updateTripLocation({
    required String tripId,
    required double lat,
    required double lng,
  });

  /// Updates the trip's rotating BLE OTP and expiry.
  Future<void> updateTripBleOtp({
    required String tripId,
    required String otp,
    required String expiresAt,
  });

  /// Bulk-submits cached offline locations via
  /// `bulk_update_trip_locations` RPC.
  Future<void> bulkUpdateTripLocations(List<Map<String, dynamic>> locations);

  /// Creates a payment intent via the `create_payment` RPC.
  Future<Map<String, dynamic>> createPayment({
    required String routeId,
    required int amount,
    required String currency,
    required String method,
  });

  /// Fetches a payment row by id.
  Future<Map<String, dynamic>?> getPaymentStatus(String paymentId);

  /// Fetches pending payments for the current user.
  Future<List<Map<String, dynamic>>> getPendingPayments();

  /// Fetches a driver row by id.
  Future<Map<String, dynamic>?> getDriverById(String driverId);

  /// Submits a rating for a completed trip.
  Future<Map<String, dynamic>> submitRating({
    required String tripId,
    required String driverId,
    required String studentId,
    required int rating,
    String? comment,
  });

  /// Fetches the student's existing rating for a trip, or `null`.
  Future<Map<String, dynamic>?> getTripRating({
    required String tripId,
    required String studentId,
  });
}

@LazySingleton(as: TripRemoteDatasource)
class TripRemoteDatasourceImpl implements TripRemoteDatasource {
  TripRemoteDatasourceImpl({SayrSupabase? supabase})
      : _supabase = supabase ?? SayrSupabase.instance;
  final SayrSupabase _supabase;

  supabase.SupabaseClient get _client => _supabase.client;

  @override
  Future<List<Map<String, dynamic>>> getActiveTrips() async {
    final response = await _client.from('trips').select().inFilter('status', [
      'scheduled',
      'driver_waiting',
      'in_transit',
    ]).order('scheduled_at', ascending: true)
      .timeout(const Duration(seconds: 15));
    return List<Map<String, dynamic>>.from(response as Iterable);
  }

  @override
  Future<String> createTrip({
    required String routeId,
    required DateTime scheduledAt,
  }) =>
      _client.rpc<String>(
        'create_trip',
        params: {
          'p_route_id': routeId,
          'p_scheduled_at': scheduledAt.toUtc().toIso8601String(),
        },
      ).timeout(const Duration(seconds: 15));

  @override
  Stream<List<Map<String, dynamic>>> watchTrip(String tripId) => _client
      .from('trips')
      .stream(primaryKey: ['id'])
      .eq('id', tripId)
      .map((List<Map<String, dynamic>> rows) => rows);

  @override
  Future<Map<String, dynamic>?> getTripById(String id) =>
      _client.from('trips').select().eq('id', id).maybeSingle()
        .timeout(const Duration(seconds: 15));

  @override
  Future<Map<String, dynamic>> updateTripStatus({
    required String tripId,
    required String newStatus,
    double? lat,
    double? lng,
  }) =>
      _client.rpc<Map<String, dynamic>>(
        'update_trip_status',
        params: {
          'p_trip_id': tripId,
          'p_new_status': newStatus,
          'p_lat': lat,
          'p_lng': lng,
        },
      ).timeout(const Duration(seconds: 15));

  @override
  Future<void> updateTripLocation({
    required String tripId,
    required double lat,
    required double lng,
  }) =>
      _client.rpc<void>(
        'update_trip_location',
        params: {
          'p_trip_id': tripId,
          'p_lat': lat,
          'p_lng': lng,
        },
      ).timeout(const Duration(seconds: 15));

  @override
  Future<void> updateTripBleOtp({
    required String tripId,
    required String otp,
    required String expiresAt,
  }) async {
    await _client.rpc<void>(
      'update_trip_ble_otp',
      params: {
        'p_trip_id': tripId,
        'p_otp': otp,
        'p_expires_at': expiresAt,
      },
    ).timeout(const Duration(seconds: 15));
  }

  @override
  Future<void> bulkUpdateTripLocations(
    List<Map<String, dynamic>> locations,
  ) =>
      _client.rpc<void>(
        'bulk_update_trip_locations',
        params: {'p_locations': locations},
      ).timeout(const Duration(seconds: 15));

  @override
  Future<Map<String, dynamic>> createPayment({
    required String routeId,
    required int amount,
    required String currency,
    required String method,
  }) =>
      _client.rpc<Map<String, dynamic>>(
        'create_payment',
        params: {
          'p_route_id': routeId,
          'p_amount': amount,
          'p_currency': currency,
          'p_method': method,
        },
      ).timeout(const Duration(seconds: 15));

  @override
  Future<Map<String, dynamic>?> getPaymentStatus(String paymentId) =>
      _client.from('payments').select().eq('id', paymentId).maybeSingle()
        .timeout(const Duration(seconds: 15));

  @override
  Future<List<Map<String, dynamic>>> getPendingPayments() async {
    final response = await _client
        .from('payments')
        .select()
        .eq('status', 'pending')
        .eq('method', 'zaincash')
        .order('created_at', ascending: false)
        .timeout(const Duration(seconds: 15));
    return List<Map<String, dynamic>>.from(response as Iterable);
  }

  @override
  Future<Map<String, dynamic>?> getDriverById(String driverId) =>
      _client.from('drivers').select().eq('id', driverId).maybeSingle()
        .timeout(const Duration(seconds: 15));

  @override
  Future<Map<String, dynamic>> submitRating({
    required String tripId,
    required String driverId,
    required String studentId,
    required int rating,
    String? comment,
  }) async {
    final response = await _client
        .from('ratings')
        .insert({
          'trip_id': tripId,
          'driver_id': driverId,
          'student_id': studentId,
          'rating': rating,
          if (comment != null) 'comment': comment,
        })
        .select()
        .single()
        .timeout(const Duration(seconds: 15));
    return response;
  }

  @override
  Future<Map<String, dynamic>?> getTripRating({
    required String tripId,
    required String studentId,
  }) =>
      _client
          .from('ratings')
          .select()
          .eq('trip_id', tripId)
          .eq('student_id', studentId)
          .maybeSingle()
          .timeout(const Duration(seconds: 15));
}
