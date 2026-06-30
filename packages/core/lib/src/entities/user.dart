import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/src/enums/user_role.dart';
import 'package:sayr_core/src/value_objects/ids.dart';

part 'user.freezed.dart';
/// A user (student, driver, or admin) in the system.
@freezed
abstract class User with _$User {
  const factory User({
    required UserId id,
    required String email,
    required UserRole role,
    String? fullName,
    String? phone,
    InstitutionId? institutionId,
    @Default(false) bool isVerified,
    String? avatarUrl,
  }) = _User;

  const User._();

  /// Display name with fallback to email.
  String get displayName => fullName ?? email.split('@').first;

  /// Whether this user's profile is complete.
  bool get isProfileComplete => phone != null && institutionId != null;

  /// Whether this user is a student.
  bool get isStudent => role.isStudent;

  /// Whether this user is a driver.
  bool get isDriver => role.isDriver;

  /// Whether this user is an admin.
  bool get isAdmin => role.isAdmin;
}
