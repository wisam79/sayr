/// User roles in the system.
///
/// Roles are stored in `app_metadata.role` (not `user_metadata`)
/// for security - client cannot modify.
enum UserRole {
  /// Administrator with full access
  admin,

  /// Student who books subscriptions
  student,

  /// Driver who operates routes and trips
  driver;

  /// Whether this role can access the admin dashboard.
  bool get isAdmin => this == UserRole.admin;

  /// Whether this role operates vehicles.
  bool get isDriver => this == UserRole.driver;

  /// Whether this role books subscriptions.
  bool get isStudent => this == UserRole.student;

  /// Parse from string (database value).
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Unknown UserRole: $value'),
    );
  }
}
