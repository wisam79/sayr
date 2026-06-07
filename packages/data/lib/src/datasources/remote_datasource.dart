import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:sayr_data/src/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

abstract class RemoteDatasource {
  supabase.User? get currentUser;
  Stream<supabase.AuthState> get authStateChanges;
  Future<supabase.AuthResponse> signInWithPassword({
    required String email,
    required String password,
  });
  Future<supabase.AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  });
  Future<bool> signInWithGoogle();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> updatePassword(String password);
  Future<void> signOut();
  Future<Map<String, dynamic>?> fetchCurrentProfile(String userId);
  Future<void> updateProfile({
    required String userId,
    required String phone,
    required String institutionId,
  });
  Future<List<Map<String, dynamic>>> getInstitutions();

  // Chat
  Future<List<Map<String, dynamic>>> getMyConversations(String currentUserId);
  Stream<List<Map<String, dynamic>>> watchMyConversations(String currentUserId);
  Future<Map<String, dynamic>?> getConversation({
    required String routeId,
    required String studentId,
  });
  Future<Map<String, dynamic>> createConversation({
    required String routeId,
    required String studentId,
    required String driverUserId,
  });
  Future<List<Map<String, dynamic>>> getMessages(String conversationId);
  Stream<List<Map<String, dynamic>>> watchMessages(String conversationId);
  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String senderId,
    required String body,
  });
  Future<void> markMessageAsRead({
    required String messageId,
    required String readAt,
  });
  Future<int> getUnreadChatCount();
  Future<void> updateConversationPreview({
    required String conversationId,
    required String body,
    required String updatedAt,
  });

  // Emergency
  Future<String> triggerEmergency({
    required String tripId,
    required String routeId,
    required String studentId,
    required double lat,
    required double lng,
    required String description,
  });
  Future<Map<String, dynamic>?> getActiveEmergencyReport(String userId);
  Future<void> resolveEmergencyReport({
    required String id,
    required String resolvedAt,
  });

  // Notifications
  Future<List<Map<String, dynamic>>> getMyNotifications({
    required String userId,
    int limit = 50,
  });
  Future<int> getUnreadNotificationCount(String userId);
  Future<void> markNotificationAsRead({
    required String id,
    required String readAt,
  });
  Future<void> markAllNotificationsAsRead({
    required String userId,
    required String readAt,
  });
  Stream<List<Map<String, dynamic>>> watchMyNotifications(String userId);
  Future<void> registerPushToken({
    required String fcmToken,
    required String platform,
    String? deviceId,
  });

  // Routes
  Future<List<Map<String, dynamic>>> getActiveRoutes();
  Future<List<Map<String, dynamic>>> getMyDriverRoutes();
  Future<Map<String, dynamic>?> getRouteById(String id);
  Future<List<Map<String, dynamic>>> searchRoutes(String query);

  // Subscriptions
  Future<List<Map<String, dynamic>>> getMySubscriptions(String studentId);
  Future<void> cancelSubscription(String subscriptionId);
  Future<String> activateLicense(String code);

  // Trips
  Future<List<Map<String, dynamic>>> getActiveTrips();
  Future<String> createTrip({
    required String routeId,
    required DateTime scheduledAt,
  });
  Stream<List<Map<String, dynamic>>> watchTrip(String tripId);
  Future<Map<String, dynamic>?> getTripById(String id);
  Future<Map<String, dynamic>> updateTripStatus({
    required String tripId,
    required String newStatus,
    double? lat,
    double? lng,
  });
  Future<void> updateTripLocation({
    required String tripId,
    required double lat,
    required double lng,
  });
  Future<void> updateTripBleOtp({
    required String tripId,
    required String otp,
    required String expiresAt,
  });
  Future<void> bulkUpdateTripLocations(List<Map<String, dynamic>> locations);
  Future<Map<String, dynamic>> createPayment({
    required String routeId,
    required int amount,
    required String currency,
    required String method,
  });
  Future<Map<String, dynamic>?> getPaymentStatus(String paymentId);
  Future<Map<String, dynamic>?> getDriverById(String driverId);
  Future<Map<String, dynamic>> submitRating({
    required String tripId,
    required String driverId,
    required String studentId,
    required int rating,
    String? comment,
  });
  Future<Map<String, dynamic>?> getTripRating({
    required String tripId,
    required String studentId,
  });

  // Boarding (QR)
  Future<String?> getActiveTripForSubscription();
  Future<({String token, DateTime expiresAt})> generateBoardingToken(
    String tripId,
  );
  Future<Map<String, dynamic>> validateBoarding({
    required String token,
    required String tripId,
    double? lat,
    double? lng,
  });
  Future<List<Map<String, dynamic>>> getTripPassengers(String tripId);
  Stream<List<Map<String, dynamic>>> watchTripPassengers(String tripId);
  Future<Map<String, dynamic>> validateBoardingViaProximity({
    required String tripId,
    required String otp,
    double? lat,
    double? lng,
  });
}

@LazySingleton(as: RemoteDatasource)
class RemoteDatasourceImpl implements RemoteDatasource {
  RemoteDatasourceImpl({SayrSupabase? supabase})
      : _supabase = supabase ?? SayrSupabase.instance;
  final SayrSupabase _supabase;

  supabase.SupabaseClient get _client => _supabase.client;

  @override
  supabase.User? get currentUser => _supabase.currentUser;

  @override
  Stream<supabase.AuthState> get authStateChanges => _supabase.authStateChanges;

  @override
  Future<supabase.AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _supabase.signInWithPassword(email: email, password: password);
  }

  @override
  Future<supabase.AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) {
    return _supabase.signUp(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );
  }

  @override
  Future<bool> signInWithGoogle() {
    return _supabase.signInWithGoogle();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _supabase.sendPasswordResetEmail(email);
  }

  @override
  Future<void> updatePassword(String password) {
    return _supabase.updatePassword(password);
  }

  @override
  Future<void> signOut() {
    return _supabase.signOut();
  }

  @override
  Future<Map<String, dynamic>?> fetchCurrentProfile(String userId) async {
    return _client.from('profiles').select().eq('id', userId).maybeSingle();
  }

  @override
  Future<void> updateProfile({
    required String userId,
    required String phone,
    required String institutionId,
  }) async {
    await _client.from('profiles').update({
      'phone': phone,
      'institution_id': institutionId,
    }).eq('id', userId);
  }

  @override
  Future<List<Map<String, dynamic>>> getInstitutions() async {
    final response = await _client
        .from('institutions')
        .select('id, name, city')
        .eq('is_active', true)
        .order('name');
    return (response as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> getMyConversations(
    String currentUserId,
  ) async {
    final response = await _client
        .from('conversations')
        .select('''
          id,
          route_id,
          student_id,
          driver_user_id,
          last_message_at,
          last_message_preview,
          created_at,
          updated_at,
          routes:route_id ( title ),
          student:profiles!conversations_student_id_fkey ( full_name ),
          driver:profiles!conversations_driver_user_id_fkey ( full_name )
        ''')
        .or('student_id.eq.$currentUserId,driver_user_id.eq.$currentUserId')
        .order('updated_at', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchMyConversations(
    String currentUserId,
  ) {
    return _client
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('updated_at')
        .map((rows) => rows.cast<Map<String, dynamic>>());
  }

  @override
  Future<Map<String, dynamic>?> getConversation({
    required String routeId,
    required String studentId,
  }) async {
    final result = await _client
        .from('conversations')
        .select()
        .eq('route_id', routeId)
        .eq('student_id', studentId)
        .maybeSingle();
    return result;
  }

  @override
  Future<Map<String, dynamic>> createConversation({
    required String routeId,
    required String studentId,
    required String driverUserId,
  }) async {
    final response = await _client
        .from('conversations')
        .insert({
          'route_id': routeId,
          'student_id': studentId,
          'driver_user_id': driverUserId,
        })
        .select()
        .single();
    return response;
  }

  @override
  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .limit(50);
    return (response as List).cast<Map<String, dynamic>>();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchMessages(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .map((rows) => rows.cast<Map<String, dynamic>>());
  }

  @override
  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String senderId,
    required String body,
  }) async {
    final response = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': senderId,
          'body': body,
        })
        .select()
        .single();
    return response;
  }

  @override
  Future<void> markMessageAsRead({
    required String messageId,
    required String readAt,
  }) async {
    await _client.from('messages').update({
      'is_read': true,
      'read_at': readAt,
    }).eq('id', messageId);
  }

  @override
  Future<int> getUnreadChatCount() async {
    return _client.rpc<int>('get_unread_count');
  }

  @override
  Future<void> updateConversationPreview({
    required String conversationId,
    required String body,
    required String updatedAt,
  }) async {
    final preview = body.length > 100 ? body.substring(0, 100) : body;
    await _client.from('conversations').update({
      'last_message_at': updatedAt,
      'last_message_preview': preview,
    }).eq('id', conversationId);
  }

  @override
  Future<String> triggerEmergency({
    required String tripId,
    required String routeId,
    required String studentId,
    required double lat,
    required double lng,
    required String description,
  }) async {
    final response = await _client.functions.invoke(
      'emergency-alert',
      body: {
        'studentId': studentId,
        'routeId': routeId,
        'tripId': tripId,
        'lat': lat,
        'lng': lng,
        'description': description,
      },
    );
    final data = response.data as Map<String, dynamic>?;
    final reportId = data?['reportId'] as String?;
    if (reportId == null) {
      throw StateError('Empty response from emergency-alert');
    }
    return reportId;
  }

  @override
  Future<Map<String, dynamic>?> getActiveEmergencyReport(String userId) async {
    return _client
        .from('emergency_reports')
        .select()
        .eq('user_id', userId)
        .neq('status', 'resolved')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  @override
  Future<void> resolveEmergencyReport({
    required String id,
    required String resolvedAt,
  }) async {
    await _client.from('emergency_reports').update({
      'status': 'resolved',
      'resolved_at': resolvedAt,
    }).eq('id', id);
  }

  @override
  Future<List<Map<String, dynamic>>> getMyNotifications({
    required String userId,
    int limit = 50,
  }) async {
    final response = await _client
        .from('notification_log')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (response as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<int> getUnreadNotificationCount(String userId) async {
    final response = await _client
        .from('notification_log')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);
    return (response as List).length;
  }

  @override
  Future<void> markNotificationAsRead({
    required String id,
    required String readAt,
  }) async {
    await _client.from('notification_log').update({
      'is_read': true,
      'read_at': readAt,
    }).eq('id', id);
  }

  @override
  Future<void> markAllNotificationsAsRead({
    required String userId,
    required String readAt,
  }) async {
    await _client
        .from('notification_log')
        .update({
          'is_read': true,
          'read_at': readAt,
        })
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchMyNotifications(String userId) {
    return _client
        .from('notification_log')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) => rows.cast<Map<String, dynamic>>());
  }

  @override
  Future<void> registerPushToken({
    required String fcmToken,
    required String platform,
    String? deviceId,
  }) async {
    await _client.rpc<void>(
      'register_push_token',
      params: {
        'p_token': fcmToken,
        'p_platform': platform,
        if (deviceId != null) 'p_device_id': deviceId,
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getActiveRoutes() async {
    final response = await _client
        .from('routes')
        .select()
        .eq('is_active', true)
        .order('title');
    return (response as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> getMyDriverRoutes() async {
    final userId = currentUser?.id;
    if (userId == null) {
      throw const supabase.AuthException('Not authenticated');
    }

    final driver = await _client
        .from('drivers')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();
    final driverId = driver?['id'] as String?;
    if (driverId == null) {
      return <Map<String, dynamic>>[];
    }

    final response = await _client
        .from('routes')
        .select()
        .eq('driver_id', driverId)
        .eq('is_active', true)
        .order('title');
    return (response as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>?> getRouteById(String id) async {
    return _client.from('routes').select().eq('id', id).maybeSingle();
  }

  @override
  Future<List<Map<String, dynamic>>> searchRoutes(String query) async {
    final response = await _client
        .from('routes')
        .select()
        .eq('is_active', true)
        .or('title.ilike.%$query%,start_location.ilike.%$query%,end_location.ilike.%$query%')
        .order('title');
    return (response as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> getMySubscriptions(
    String studentId,
  ) async {
    final response = await _client
        .from('subscriptions')
        .select()
        .eq('student_id', studentId)
        .order('start_date', ascending: false);
    return (response as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> cancelSubscription(String subscriptionId) async {
    await _client.rpc<void>(
      'cancel_subscription',
      params: {'p_subscription_id': subscriptionId},
    );
  }

  @override
  Future<String> activateLicense(String code) async {
    return _client.rpc<String>(
      'activate_license',
      params: {'p_code': code},
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getActiveTrips() async {
    final response = await _client.from('trips').select().inFilter('status', [
      'scheduled',
      'driver_waiting',
      'in_transit',
    ]).order('scheduled_at', ascending: true);
    return (response as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<String> createTrip({
    required String routeId,
    required DateTime scheduledAt,
  }) async {
    return _client.rpc<String>(
      'create_trip',
      params: {
        'p_route_id': routeId,
        'p_scheduled_at': scheduledAt.toUtc().toIso8601String(),
      },
    );
  }

  @override
  Stream<List<Map<String, dynamic>>> watchTrip(String tripId) {
    return _client
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('id', tripId)
        .map((rows) => rows.cast<Map<String, dynamic>>());
  }

  @override
  Future<Map<String, dynamic>?> getTripById(String id) async {
    return _client.from('trips').select().eq('id', id).maybeSingle();
  }

  @override
  Future<Map<String, dynamic>> updateTripStatus({
    required String tripId,
    required String newStatus,
    double? lat,
    double? lng,
  }) async {
    final response = await _client.rpc<Map<String, dynamic>>(
      'update_trip_status',
      params: {
        'p_trip_id': tripId,
        'p_new_status': newStatus,
        'p_lat': lat,
        'p_lng': lng,
      },
    );
    return response;
  }

  @override
  Future<void> updateTripLocation({
    required String tripId,
    required double lat,
    required double lng,
  }) async {
    await _client.rpc<void>(
      'update_trip_location',
      params: {
        'p_trip_id': tripId,
        'p_lat': lat,
        'p_lng': lng,
      },
    );
  }

  @override
  Future<void> updateTripBleOtp({
    required String tripId,
    required String otp,
    required String expiresAt,
  }) async {
    await _client.from('trips').update({
      'ble_otp': otp,
      'ble_otp_expires_at': expiresAt,
    }).eq('id', tripId);
  }

  @override
  Future<void> bulkUpdateTripLocations(
    List<Map<String, dynamic>> locations,
  ) async {
    await _client.rpc<void>(
      'bulk_update_trip_locations',
      params: {'p_locations': locations},
    );
  }

  @override
  Future<Map<String, dynamic>> createPayment({
    required String routeId,
    required int amount,
    required String currency,
    required String method,
  }) async {
    final response = await _client.rpc<Map<String, dynamic>>(
      'create_payment',
      params: {
        'p_route_id': routeId,
        'p_amount': amount,
        'p_currency': currency,
        'p_method': method,
      },
    );
    return response;
  }

  @override
  Future<Map<String, dynamic>?> getPaymentStatus(String paymentId) async {
    return _client.from('payments').select().eq('id', paymentId).maybeSingle();
  }

  @override
  Future<Map<String, dynamic>?> getDriverById(String driverId) async {
    return _client.from('drivers').select().eq('id', driverId).maybeSingle();
  }

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
        .single();
    return response;
  }

  @override
  Future<Map<String, dynamic>?> getTripRating({
    required String tripId,
    required String studentId,
  }) async {
    return _client
        .from('ratings')
        .select()
        .eq('trip_id', tripId)
        .eq('student_id', studentId)
        .maybeSingle();
  }

  // Boarding (QR)
  @override
  Future<String?> getActiveTripForSubscription() async {
    final userId = currentUser?.id;
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
  Stream<List<Map<String, dynamic>>> watchTripPassengers(String tripId) {
    return _client
        .from('boardings')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .order('boarded_at')
        .map((rows) => rows.cast<Map<String, dynamic>>());
  }

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
