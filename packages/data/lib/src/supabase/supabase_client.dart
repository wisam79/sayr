import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'supabase_config.dart';

/// Wraps the Supabase client with Sayr-specific configuration.
///
/// Use [SayrSupabase.instance] to access the singleton client.
class SayrSupabase {
  SayrSupabase._();

  static SayrSupabase? _instance;

  /// The singleton instance.
  static SayrSupabase get instance => _instance ??= SayrSupabase._();

  late supabase.SupabaseClient _client;
  bool _initialized = false;

  /// The underlying Supabase client.
  supabase.SupabaseClient get client {
    if (!_initialized) {
      throw StateError('SayrSupabase not initialized. Call init() first.');
    }
    return _client;
  }

  /// The current authenticated user, or null if not signed in.
  supabase.User? get currentUser => _client.auth.currentUser;

  /// Initialize the Supabase client.
  ///
  /// Must be called once during app startup (e.g., in main()).
  Future<void> init({SupabaseConfig? config}) async {
    if (_initialized) return;

    final cfg = config ?? SupabaseConfig.fromEnv();

    await supabase.Supabase.initialize(
      url: cfg.url,
      anonKey: cfg.anonKey,
      authOptions: const supabase.FlutterAuthClientOptions(
        authFlowType: supabase.AuthFlowType.pkce,
      ),
    );

    _client = supabase.Supabase.instance.client;
    _initialized = true;
  }

  /// Sign in with email and password.
  Future<supabase.AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Sign up with email and password.
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

  /// Sign in with Google via OAuth.
  ///
  /// Returns true on success. The user becomes available via
  /// [currentUser] or the [authStateChanges] stream once the OAuth
  /// flow completes and Supabase processes the callback.
  Future<bool> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      supabase.OAuthProvider.google,
      redirectTo: 'com.sayr.app://login-callback',
    );
  }

  /// Send a password reset email.
  Future<void> sendPasswordResetEmail(String email) {
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'com.sayr.app://reset-password',
    );
  }

  /// Update the current user's password.
  Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(
      supabase.UserAttributes(password: password),
    );
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Listen to auth state changes.
  Stream<supabase.AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;
}
