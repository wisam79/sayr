import 'package:injectable/injectable.dart';
import 'package:sayr_data/src/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// QR boarding token generation, validation, and passenger listing.
abstract class BoardingRemoteDatasource {
  /// Returns the active trip id for the current student's active
  /// subscription, or `null` if none.
  Future<String?> getActiveTripForSubscription();

  /// Generates a one-time boarding token for the trip via the
  /// `generate_boarding_token` RPC.
  Future<({String token, DateTime expiresAt})> generateBoardingToken(
    String tripId,
  );

  /// Validates a boarding token via the `validate_boarding` RPC.
  Future<Map<String, dynamic>> validateBoarding({
    required String token,
    required String tripId,
    double? lat,
    double? lng,
  });

  /// Lists the boarded passengers for a trip.
  Future<List<Map<String, dynamic>>> getTripPassengers(String tripId);

  /// Realtime stream of boarded passengers for a trip.
  Stream<List<Map<String, dynamic>>> watchTripPassengers(String tripId);

  /// Validates boarding via BLE OTP + optional proximity via the
  /// `validate_boarding_via_proximity` RPC.
  Future<Map<String, dynamic>> validateBoardingViaProximity({
    required String tripId,
    required String otp,
    double? lat,
    double? lng,
  });
}

@LazySingleton(as: BoardingRemoteDatasource)
class BoardingRemoteDatasourceImpl implements BoardingRemoteDatasource {
  BoardingRemoteDatasourceImpl({SayrSupabase? supabase})
      : _supabase = supabase ?? SayrSupabase.instance;
  final SayrSupabase _supabase;

  supabase.SupabaseClient get _client => _supabase.client;
  supabase.User? get _currentUser => _supabase.currentUser;

  @override
  Future<String?> getActiveTripForSubscription() async {
    final userId = _currentUser?.id;
    if (userId == null) {
      throw const supabase.AuthException('Not authenticated');
    }
    final sub = await _client
        .from('subscriptions')
        .select('route_id')
        .eq('student_id', userId)
        .eq('status', 'active')
        .order('start_date', ascending: false)
        .limit(1)
        .maybeSingle();
    final routeId = sub?['route_id'] as String?;
    if (routeId == null) return null;
    return _client.rpc<String?>(
      'get_active_trip_for_route',
      params: {'p_route_id': routeId},
    );
  }

  @override
  Future<({String token, DateTime expiresAt})> generateBoardingToken(
    String tripId,
  ) async {
    final response = await _client.rpc<List<dynamic>>(
      'generate_boarding_token',
      params: {'p_trip_id': tripId},
    );
    if (response.isEmpty) {
      throw const supabase.PostgrestException(
        message: 'Empty response from generate_boarding_token',
      );
    }
    final row = (response.first as Map).cast<String, dynamic>();
    return (
      token: row['token'] as String,
      expiresAt: DateTime.parse(row['expires_at'] as String),
    );
  }

  @override
  Future<Map<String, dynamic>> validateBoarding({
    required String token,
    required String tripId,
    double? lat,
    double? lng,
  }) async {
    final response = await _client.rpc<List<dynamic>>(
      'validate_boarding',
      params: {
        'p_token': token,
        'p_trip_id': tripId,
        'p_lat': lat,
        'p_lng': lng,
      },
    );
    if (response.isEmpty) {
      throw const supabase.PostgrestException(
        message: 'Empty response from validate_boarding',
      );
    }
    return (response.first as Map).cast<String, dynamic>();
  }

  @override
  Future<List<Map<String, dynamic>>> getTripPassengers(String tripId) async {
    final response = await _client.rpc<List<dynamic>>(
      'get_trip_passengers',
      params: {'p_trip_id': tripId},
    );
    return response.map((r) => (r as Map).cast<String, dynamic>()).toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchTripPassengers(String tripId) =>
      _client
          .from('boardings')
          .stream(primaryKey: ['id'])
          .eq('trip_id', tripId)
          .order('boarded_at')
          .map((rows) => rows.cast<Map<String, dynamic>>());

  @override
  Future<Map<String, dynamic>> validateBoardingViaProximity({
    required String tripId,
    required String otp,
    double? lat,
    double? lng,
  }) async {
    final response = await _client.rpc<List<dynamic>>(
      'validate_boarding_via_proximity',
      params: {
        'p_trip_id': tripId,
        'p_otp': otp,
        if (lat != null) 'p_student_lat': lat,
        if (lng != null) 'p_student_lng': lng,
      },
    );
    if (response.isEmpty) {
      throw const supabase.PostgrestException(
        message: 'Empty response from validate_boarding_via_proximity',
      );
    }
    return (response.first as Map).cast<String, dynamic>();
  }
}
