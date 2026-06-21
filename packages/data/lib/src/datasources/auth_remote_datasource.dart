import 'package:injectable/injectable.dart';
import 'package:sayr_data/src/models/user_model.dart';
import 'package:sayr_data/src/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Auth-related remote operations (Supabase Auth + profiles + institutions).
abstract class AuthRemoteDatasource {
  /// Current authenticated user, or `null` if not signed in.
  supabase.User? get currentUser;

  /// Stream of Supabase auth state changes.
  Stream<supabase.AuthState> get authStateChanges;

  /// Signs in with email + password.
  Future<supabase.AuthResponse> signInWithPassword({
    required String email,
    required String password,
  });

  /// Registers a new user.
  Future<supabase.AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  });

  /// Triggers Google OAuth flow. Returns `true` on success.
  Future<bool> signInWithGoogle();

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail(String email);

  /// Updates the current user's password.
  Future<void> updatePassword(String password);

  /// Signs the current user out of both Supabase and Google.
  Future<void> signOut();

  /// Fetches the current user's profile row.
  Future<UserModel?> fetchCurrentProfile(String userId);

  /// Fetches a user's safe/public profile details from the profiles_public view.
  Future<UserModel?> fetchPublicProfile(String userId);

  /// Fetches multiple users' safe/public profiles from the profiles_public view.
  Future<List<UserModel>> getPublicProfiles(List<String> userIds);

  /// Updates the current user's profile phone and institution.
  Future<void> updateProfile({
    required String phone,
    required String institutionId,
  });

  /// Returns the list of active institutions for the onboarding picker.
  Future<List<Map<String, dynamic>>> getInstitutions();
}

@LazySingleton(as: AuthRemoteDatasource)
class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  AuthRemoteDatasourceImpl({SayrSupabase? supabase})
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
  }) =>
      _supabase.signInWithPassword(email: email, password: password);

  @override
  Future<supabase.AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) =>
      _supabase.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );

  @override
  Future<bool> signInWithGoogle() => _supabase.signInWithGoogle();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _supabase.sendPasswordResetEmail(email);

  @override
  Future<void> updatePassword(String password) =>
      _supabase.updatePassword(password);

  @override
  Future<void> signOut() => _supabase.signOut();

  @override
  Future<UserModel?> fetchCurrentProfile(String userId) async {
    final data = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    return data != null ? UserModel.fromJson(data) : null;
  }

  @override
  Future<UserModel?> fetchPublicProfile(String userId) async {
    final data = await _client.from('profiles_public').select().eq('id', userId).maybeSingle();
    return data != null ? UserModel.fromJson(data) : null;
  }

  @override
  Future<List<UserModel>> getPublicProfiles(List<String> userIds) async {
    if (userIds.isEmpty) return const [];
    return await _client
        .from('profiles_public')
        .select('id, full_name, avatar_url')
        .inFilter('id', userIds)
        .withConverter((data) => data.map((e) => UserModel.fromJson(e)).toList());
  }

  @override
  Future<void> updateProfile({
    required String phone,
    required String institutionId,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      throw const supabase.AuthException('User not authenticated');
    }
    await _client.from('profiles').update({
      'phone': phone,
      'institution_id': institutionId,
    }).eq('id', currentUserId);
  }

  @override
  Future<List<Map<String, dynamic>>> getInstitutions() async {
    final response = await _client
        .from('institutions')
        .select('id, name, city')
        .eq('is_active', true)
        .order('name');
    return List<Map<String, dynamic>>.from(response as Iterable);
  }
}
