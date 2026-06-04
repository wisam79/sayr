import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Secure storage for sensitive data (tokens, credentials).
@lazySingleton
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
            );

  final FlutterSecureStorage _storage;

  static const _kAuthTokenKey = 'auth_token';
  static const _kRefreshTokenKey = 'refresh_token';
  static const _kUserIdKey = 'user_id';

  /// Store the access token.
  Future<void> setAuthToken(String token) =>
      _storage.write(key: _kAuthTokenKey, value: token);

  /// Get the access token.
  Future<String?> getAuthToken() => _storage.read(key: _kAuthTokenKey);

  /// Store the refresh token.
  Future<void> setRefreshToken(String token) =>
      _storage.write(key: _kRefreshTokenKey, value: token);

  /// Get the refresh token.
  Future<String?> getRefreshToken() => _storage.read(key: _kRefreshTokenKey);

  /// Store the current user ID.
  Future<void> setUserId(String userId) =>
      _storage.write(key: _kUserIdKey, value: userId);

  /// Get the current user ID.
  Future<String?> getUserId() => _storage.read(key: _kUserIdKey);

  /// Clear all stored tokens.
  Future<void> clear() async {
    await _storage.delete(key: _kAuthTokenKey);
    await _storage.delete(key: _kRefreshTokenKey);
    await _storage.delete(key: _kUserIdKey);
  }
}
