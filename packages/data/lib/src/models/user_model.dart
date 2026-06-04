import 'package:sayr_core/sayr_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../supabase/supabase_client.dart';

/// DTO for User from Supabase.
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
    this.phone,
    this.institutionId,
    this.isVerified = false,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String? ?? 'student'),
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      institutionId: json['institution_id'] != null
          ? InstitutionId(json['institution_id'] as String)
          : null,
      isVerified: json['is_verified'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

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

  final String id;
  final String email;
  final UserRole role;
  final String? fullName;
  final String? phone;
  final InstitutionId? institutionId;
  final bool isVerified;
  final String? avatarUrl;

  /// Convert to a domain entity.
  User toEntity() => User(
        id: UserId(id),
        email: email,
        role: role,
        fullName: fullName,
        phone: phone,
        institutionId: institutionId,
        isVerified: isVerified,
        avatarUrl: avatarUrl,
      );

  /// Fetch the current user's profile from Supabase.
  static Future<UserModel?> fetchCurrent() async {
    final client = SayrSupabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return null;

    final response = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }
}
