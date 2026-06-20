import 'package:freezed_annotation/freezed_annotation.dart';

/// The authentication status of the current user.
enum AuthStatus {
  /// User is fully authenticated.
  @JsonValue('authenticated')
  authenticated,

  /// User is not authenticated.
  @JsonValue('unauthenticated')
  unauthenticated,
}
