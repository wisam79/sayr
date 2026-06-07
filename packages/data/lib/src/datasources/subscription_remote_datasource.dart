import 'package:injectable/injectable.dart';
import 'package:sayr_data/src/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Student subscriptions + license activation.
abstract class SubscriptionRemoteDatasource {
  /// Fetches the student's subscriptions, newest first.
  Future<List<Map<String, dynamic>>> getMySubscriptions(String studentId);

  /// Cancels a subscription via the `cancel_subscription` RPC.
  Future<void> cancelSubscription(String subscriptionId);

  /// Activates a license code via the `activate_license` RPC.
  /// Returns the new subscription id.
  Future<String> activateLicense(String code);
}

@LazySingleton(as: SubscriptionRemoteDatasource)
class SubscriptionRemoteDatasourceImpl implements SubscriptionRemoteDatasource {
  SubscriptionRemoteDatasourceImpl({SayrSupabase? supabase})
      : _supabase = supabase ?? SayrSupabase.instance;
  final SayrSupabase _supabase;

  supabase.SupabaseClient get _client => _supabase.client;

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
  Future<void> cancelSubscription(String subscriptionId) => _client.rpc<void>(
        'cancel_subscription',
        params: {'p_subscription_id': subscriptionId},
      );

  @override
  Future<String> activateLicense(String code) => _client.rpc<String>(
        'activate_license',
        params: {'p_code': code},
      );
}
