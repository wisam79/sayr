import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
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
  AuthRemoteDatasourceImpl({
    SayrSupabase? supabase,
  }) : _supabase = supabase ?? SayrSupabase.instance;
  final SayrSupabase _supabase;

  /// GoogleSignIn instance used for sign-in flows. Can be overridden in tests.
  GoogleSignIn? googleSignIn;

  final Logger _logger = Logger();

  supabase.SupabaseClient get _client => _supabase.client;

  @override
  supabase.User? get currentUser => _client.auth.currentUser;

  @override
  Stream<supabase.AuthState> get authStateChanges => _supabase.authStateChanges;

  @override
  Future<supabase.AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<supabase.AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        if (phone != null) 'phone': phone,
      },
    );
  }

  @override
  Future<bool> signInWithGoogle() async {
    const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    const androidClientId = String.fromEnvironment('GOOGLE_ANDROID_CLIENT_ID');
    final clientId = webClientId.isNotEmpty
        ? webClientId
        : (androidClientId.isNotEmpty ? androidClientId : null);

    final googleSignIn = this.googleSignIn ??
        GoogleSignIn(
          serverClientId: clientId,
          scopes: ['email', 'profile'],
        );

    try {
      // Force account chooser dialog by signing out from Google client first
      try {
        await googleSignIn.signOut();
      } catch (e, st) {
        _logger.d(
          'Google signOut before re-auth failed; proceeding with signIn',
          error: e,
          stackTrace: st,
        );
      }

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the native sign-in dialog
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw const supabase.AuthException(
          'google_id_token_missing',
        );
      }

      final response = await _client.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return response.user != null;
    } catch (e) {
      // Fallback to OAuth if native sign-in fails or is not supported
      if (e.toString().contains('sign_in_canceled') ||
          e.toString().contains('canceled')) {
        return false;
      }

      // Attempt OAuth fallback
      return _client.auth.signInWithOAuth(
        supabase.OAuthProvider.google,
        redirectTo: 'com.sayr.app://login-callback',
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'com.sayr.app://reset-password',
    );
  }

  @override
  Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(
      supabase.UserAttributes(password: password),
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
    try {
      await (googleSignIn ?? GoogleSignIn()).signOut();
    } catch (e, st) {
      _logger.d(
        'Google signOut during app signOut failed (likely not initialized)',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<UserModel?> fetchCurrentProfile(String userId) async {
    final data =
        await _client.from('profiles').select().eq('id', userId).maybeSingle();
    return data != null ? UserModel.fromJson(data) : null;
  }

  @override
  Future<UserModel?> fetchPublicProfile(String userId) async {
    final data = await _client
        .from('profiles_public')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return data != null ? UserModel.fromJson(data) : null;
  }

  @override
  Future<List<UserModel>> getPublicProfiles(List<String> userIds) async {
    if (userIds.isEmpty) return const [];
    return await _client
        .from('profiles_public')
        .select('id, full_name, avatar_url')
        .inFilter('id', userIds)
        .withConverter(
            (data) => data.map((e) => UserModel.fromJson(e)).toList());
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
    return await _client
        .from('institutions')
        .select('id, name, city')
        .eq('is_active', true)
        .order('name')
        .withConverter(
          (data) => (data as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
        );
  }
}
