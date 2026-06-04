import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';

import '../supabase/supabase_client.dart';

/// Repository for emergency (SOS) reports.
@lazySingleton
class EmergencyRepository {
  EmergencyRepository({SayrSupabase? supabase})
      : _supabase = supabase ?? SayrSupabase.instance;

  final SayrSupabase _supabase;

  /// Trigger an SOS via the `emergency-alert` Edge Function.
  /// The function inserts a row in `emergency_reports` and notifies
  /// every admin via FCM.
  Future<Either<Failure, EmergencyReport>> triggerEmergency({
    required TripId tripId,
    required RouteId routeId,
    required Coordinates location,
    String? message,
  }) async {
    try {
      final currentUserId = _supabase.client.auth.currentUser?.id;
      if (currentUserId == null) {
        return const Left<Failure, EmergencyReport>(UnauthorizedFailure());
      }

      final response = await _supabase.client.functions.invoke(
        'emergency-alert',
        body: {
          'studentId': currentUserId,
          'routeId': routeId.value,
          'tripId': tripId.value,
          'lat': location.latitude,
          'lng': location.longitude,
          'description': message ?? '',
        },
      );

      final data = response.data as Map<String, dynamic>?;
      final reportId = data?['reportId'] as String?;
      if (reportId == null) {
        return const Left<Failure, EmergencyReport>(
          ServerFailure(message: 'Empty response from emergency-alert'),
        );
      }

      return Right<Failure, EmergencyReport>(
        EmergencyReport(
          id: EmergencyReportId(reportId),
          userId: UserId(currentUserId),
          tripId: tripId,
          location: location,
          createdAt: DateTime.now().toUtc(),
        ),
      );
    } catch (e) {
      return Left<Failure, EmergencyReport>(
        ServerFailure(message: e.toString()),
      );
    }
  }

  /// Get the user's most recent active (unresolved) report, if any.
  Future<Either<Failure, EmergencyReport?>> getActiveReport() async {
    try {
      final currentUserId = _supabase.client.auth.currentUser?.id;
      if (currentUserId == null) {
        return const Left<Failure, EmergencyReport?>(UnauthorizedFailure());
      }

      final response = await _supabase.client
          .from('emergency_reports')
          .select()
          .eq('user_id', currentUserId)
          .neq('status', 'resolved')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return const Right<Failure, EmergencyReport?>(null);
      }

      return Right<Failure, EmergencyReport?>(_fromJson(response));
    } catch (e) {
      return Left<Failure, EmergencyReport?>(
        ServerFailure(message: e.toString()),
      );
    }
  }

  /// Resolve (cancel) an active report.
  Future<Either<Failure, Unit>> resolveReport(EmergencyReportId id) async {
    try {
      await _supabase.client
          .from('emergency_reports')
          .update({
            'status': 'resolved',
            'resolved_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id.value);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(ServerFailure(message: e.toString()));
    }
  }

  EmergencyReport _fromJson(Map<String, dynamic> json) {
    return EmergencyReport(
      id: EmergencyReportId(json['id'] as String),
      userId: UserId(json['user_id'] as String),
      tripId: TripId(json['trip_id'] as String),
      location: Coordinates(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }
}
