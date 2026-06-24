/// Supabase configuration loaded from environment.
///
/// Contains only public-safe keys. The service role key is never
/// included in client-side configuration to prevent exposure in the binary.
class SupabaseConfig {
  const SupabaseConfig({
    required this.url,
    required this.anonKey,
    this.loginRedirectUri = 'com.sayr.app://login-callback',
    this.resetPasswordRedirectUri = 'com.sayr.app://reset-password',
  })  : assert(url != '', 'url cannot be empty'),
        assert(anonKey != '', 'anonKey cannot be empty');

  /// Build from environment variables.
  factory SupabaseConfig.fromEnv() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    const loginRedirect = String.fromEnvironment(
      'SUPABASE_LOGIN_REDIRECT_URI',
      defaultValue: 'com.sayr.app://login-callback',
    );
    const resetRedirect = String.fromEnvironment(
      'SUPABASE_RESET_PASSWORD_REDIRECT_URI',
      defaultValue: 'com.sayr.app://reset-password',
    );

    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Missing required Supabase environment variables.\n'
        'Please set SUPABASE_URL and SUPABASE_ANON_KEY.\n'
        'See .env.example for details.',
      );
    }

    return SupabaseConfig(
      url: url,
      anonKey: anonKey,
      loginRedirectUri: loginRedirect,
      resetPasswordRedirectUri: resetRedirect,
    );
  }

  /// The Supabase project URL.
  final String url;

  /// The anon (public) API key.
  final String anonKey;

  /// The OAuth redirect URI for login callbacks.
  final String loginRedirectUri;

  /// The redirect URI for reset password callbacks.
  final String resetPasswordRedirectUri;
}
