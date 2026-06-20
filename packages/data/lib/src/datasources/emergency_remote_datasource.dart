import 'package:injectable/injectable.dart';
import 'package:sayr_data/src/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Emergency SOS trigger + active report lookup + resolution.
abstract class EmergencyRemoteDatasource {
  /// Invokes the `emergency-alert` Edge Function and returns the new report id.
  Future<String> triggerEmergency({
    required String tripId,
    required String routeId,
    required String studentId,
    required String description,
    double? lat,
    double? lng,
  });

  /// Returns the user's currently unresolved emergency report, or `null`.
  Future<Map<String, dynamic>?> getActiveEmergencyReport(String userId);

  /// Marks an emergency report as resolved.
  Future<void> resolveEmergencyReport({
    required String id,
    required String resolvedAt,
  });
}

@LazySingleton(as: EmergencyRemoteDatasource)
class EmergencyRemoteDatasourceImpl implements EmergencyRemoteDatasource {
  EmergencyRemoteDatasourceImpl({SayrSupabase? supabase})
      : _supabase = supabase ?? SayrSupabase.instance;
  final SayrSupabase _supabase;

  supabase.SupabaseClient get _client => _supabase.client;

  @override
  Future<String> triggerEmergency({
    required String tripId,
    required String routeId,
    required String studentId,
    required String description,
    double? lat,
    double? lng,
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
  Future<Map<String, dynamic>?> getActiveEmergencyReport(String userId) =>
      _client
          .from('emergency_reports')
          .select()
          .eq('user_id', userId)
          .neq('status', 'resolved')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

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
}
