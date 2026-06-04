/// Supabase configuration loaded from environment.
class SupabaseConfig {
  const SupabaseConfig({
    required this.url,
    required this.anonKey,
    this.serviceRoleKey,
  });

  /// The Supabase project URL.
  final String url;

  /// The anon (public) API key.
  final String anonKey;

  /// The service role key (server-side only, never expose to client).
  final String? serviceRoleKey;

  /// Build from environment variables.
  factory SupabaseConfig.fromEnv() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    const serviceRoleKey = String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY');

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
      serviceRoleKey: serviceRoleKey.isEmpty ? null : serviceRoleKey,
    );
  }
}
