import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// DTO for User from Supabase (freezed version).
@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required UserRole role,
    @Default('') String email,
    @JsonKey(name: 'full_name') String? fullName,
    String? phone,
    @JsonKey(name: 'institution_id') String? institutionId,
    @Default(false) @JsonKey(name: 'is_verified') bool isVerified,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
  }) = _UserModel;

  const UserModel._();

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  factory UserModel.fromAuthUser(supabase.User user) {
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      role: UserRole.fromString(
        user.appMetadata['role'] as String? ?? 'student',
      ),
      fullName: user.userMetadata?['full_name'] as String?,
      phone: user.userMetadata?['phone'] as String?,
    );
  }

  /// Convert to a domain entity.
  User toEntity() => User(
        id: UserId(id),
        email: email,
        role: role,
        fullName: fullName,
        phone: phone,
        institutionId:
            institutionId != null ? InstitutionId(institutionId!) : null,
        isVerified: isVerified,
        avatarUrl: avatarUrl,
      );
}
