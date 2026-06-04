/// Supabase configuration loaded from environment.
///
/// Contains only public-safe keys. The service role key is never
/// included in client-side configuration to prevent exposure in the binary.
class SupabaseConfig {
  const SupabaseConfig({
    required this.url,
    required this.anonKey,
  })  : assert(url != '', 'url cannot be empty'),
        assert(anonKey != '', 'anonKey cannot be empty');

  /// The Supabase project URL.
  final String url;

  /// The anon (public) API key.
  final String anonKey;

  /// Build from environment variables.
  factory SupabaseConfig.fromEnv() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Missing required Supabase environment variables.\n'
        'Please set SUPABASE_URL and SUPABASE_ANON_KEY.\n'
        'See .env.example for details.',
      );
    }

    return SupabaseConfig(url: url, anonKey: anonKey);
  }
}
