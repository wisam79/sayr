import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:sayr_data/src/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Wraps the Supabase client with Sayr-specific configuration.
///
/// Use [SayrSupabase.instance] to access the singleton client.
class SayrSupabase {
  SayrSupabase._();

  static SayrSupabase? _instance;

  /// The singleton instance.
  // ignore: prefer_constructors_over_static_methods, singleton getter pattern is preferred over factory in this codebase
  static SayrSupabase get instance => _instance ??= SayrSupabase._();

  late supabase.SupabaseClient _client;
  bool _initialized = false;
  final Logger _logger = Logger();

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

  /// Sign in with Google using native Google Sign-In or OAuth fallback.
  ///
  /// Returns true on success.
  Future<bool> signInWithGoogle() async {
    const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    const androidClientId = String.fromEnvironment('GOOGLE_ANDROID_CLIENT_ID');
    final clientId = webClientId.isNotEmpty
        ? webClientId
        : (androidClientId.isNotEmpty ? androidClientId : null);

    final googleSignIn = GoogleSignIn(
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
          'لم يتم استرداد معرف الهوية (ID Token) من Google.',
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
    try {
      await GoogleSignIn().signOut();
    } catch (e, st) {
      _logger.d(
        'Google signOut during app signOut failed (likely not initialized)',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Listen to auth state changes.
  Stream<supabase.AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;
}
