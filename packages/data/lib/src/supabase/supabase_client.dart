import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sayr_data/src/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Secure local storage adapter for Supabase.
class SecureSupabaseStorage extends supabase.LocalStorage {
  const SecureSupabaseStorage();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _kSupabaseSessionKey = 'supabase_session';

  static final Map<String, String> _memoryStorage = {};
  static bool _useMemoryStorage = false;

  @override
  Future<void> initialize() async {
    try {
      await _storage.read(key: _kSupabaseSessionKey);
    } catch (_) {
      _useMemoryStorage = true;
    }
  }

  @override
  Future<bool> hasAccessToken() async {
    if (_useMemoryStorage) {
      return _memoryStorage.containsKey(_kSupabaseSessionKey);
    }
    try {
      return await _storage.read(key: _kSupabaseSessionKey) != null;
    } catch (_) {
      _useMemoryStorage = true;
      return _memoryStorage.containsKey(_kSupabaseSessionKey);
    }
  }

  @override
  Future<String?> accessToken() async {
    if (_useMemoryStorage) {
      return _memoryStorage[_kSupabaseSessionKey];
    }
    try {
      return await _storage.read(key: _kSupabaseSessionKey);
    } catch (_) {
      _useMemoryStorage = true;
      return _memoryStorage[_kSupabaseSessionKey];
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    if (_useMemoryStorage) {
      _memoryStorage[_kSupabaseSessionKey] = persistSessionString;
      return;
    }
    try {
      await _storage.write(
          key: _kSupabaseSessionKey, value: persistSessionString);
    } catch (_) {
      _useMemoryStorage = true;
      _memoryStorage[_kSupabaseSessionKey] = persistSessionString;
    }
  }

  @override
  Future<void> removePersistedSession() async {
    if (_useMemoryStorage) {
      _memoryStorage.remove(_kSupabaseSessionKey);
      return;
    }
    try {
      await _storage.delete(key: _kSupabaseSessionKey);
    } catch (_) {
      _useMemoryStorage = true;
      _memoryStorage.remove(_kSupabaseSessionKey);
    }
  }
}

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
      // ignore: deprecated_member_use
      anonKey: cfg.anonKey,
      authOptions: const supabase.FlutterAuthClientOptions(
        localStorage: SecureSupabaseStorage(),
      ),
    );

    _client = supabase.Supabase.instance.client;
    _initialized = true;
  }

  /// Listen to auth state changes.
  Stream<supabase.AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;
}
