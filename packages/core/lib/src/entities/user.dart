import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/user_role.dart';
import '../value_objects/ids.dart';
import '../utils/json_converters.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// A user (student, driver, or admin) in the system.
@freezed
abstract class User with _$User {
  const factory User({
    @JsonKey(fromJson: userIdFromJson, toJson: userIdToJson) required UserId id,
    required String email,
    @JsonKey(fromJson: userRoleFromJson, toJson: userRoleToJson)
    required UserRole role,
    String? fullName,
    String? phone,
    @JsonKey(
        fromJson: nullableInstitutionIdFromJson,
        toJson: nullableInstitutionIdToJson)
    InstitutionId? institutionId,
    @Default(false) bool isVerified,
    String? avatarUrl,
  }) = _User;

  const User._();

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// Display name with fallback to email.
  String get displayName => fullName ?? email.split('@').first;

  /// Whether this user is a student.
  bool get isStudent => role.isStudent;

  /// Whether this user is a driver.
  bool get isDriver => role.isDriver;

  /// Whether this user is an admin.
  bool get isAdmin => role.isAdmin;
}
