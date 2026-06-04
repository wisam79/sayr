import 'package:equatable/equatable.dart';

import '../enums/user_role.dart';
import '../value_objects/ids.dart';

/// A user (student, driver, or admin) in the system.
class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
    this.phone,
    this.institutionId,
    this.isVerified = false,
    this.avatarUrl,
  });

  /// Unique user ID (matches `auth.users.id` in Supabase).
  final UserId id;

  /// Email address.
  final String email;

  /// User role (from `app_metadata.role`).
  final UserRole role;

  /// Full display name.
  final String? fullName;

  /// Phone number (optional).
  final String? phone;

  /// Institution (university) the user belongs to.
  final InstitutionId? institutionId;

  /// Whether the user is verified by an admin.
  final bool isVerified;

  /// URL to avatar image.
  final String? avatarUrl;

  /// Display name with fallback to email.
  String get displayName => fullName ?? email.split('@').first;

  /// Whether this user is a student.
  bool get isStudent => role.isStudent;

  /// Whether this user is a driver.
  bool get isDriver => role.isDriver;

  /// Whether this user is an admin.
  bool get isAdmin => role.isAdmin;

  @override
  List<Object?> get props => [
        id,
        email,
        role,
        fullName,
        phone,
        institutionId,
        isVerified,
        avatarUrl,
      ];
}
