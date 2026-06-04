import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../supabase/supabase_client.dart';

/// Repository for authentication and user management.
@lazySingleton
class AuthRepository {
  AuthRepository({SayrSupabase? supabase})
      : _supabase = supabase ?? SayrSupabase.instance;

  final SayrSupabase _supabase;

  /// The currently signed-in user.
  User? get currentUser {
    final authUser = _supabase.currentUser;
    if (authUser == null) return null;
    return User(
      id: UserId(authUser.id),
      email: authUser.email ?? '',
      role: UserRole.fromString(
        authUser.appMetadata['role'] as String? ?? 'student',
      ),
      fullName: authUser.userMetadata?['full_name'] as String?,
    );
  }

  /// Sign in with email and password.
  Future<Either<Failure, User>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        return const Left(UnauthorizedFailure(message: 'بيانات الدخول غير صحيحة'));
      }
      return Right(_userFromAuth(response.user!));
    } on supabase.AuthException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  /// Sign up with email and password.
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final response = await _supabase.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      if (response.user == null) {
        return const Left(ValidationFailure(message: 'فشل إنشاء الحساب'));
      }
      return Right(_userFromAuth(response.user!));
    } on supabase.AuthException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  /// Sign in with Google.
  ///
  /// The OAuth flow completes asynchronously; the resulting user is
  /// delivered through [authStateChanges] rather than this method's
  /// return value.
  Future<Either<Failure, Unit>> signInWithGoogle() async {
    try {
      final ok = await _supabase.signInWithGoogle();
      if (!ok) {
        return const Left(UnauthorizedFailure(message: 'فشل تسجيل الدخول عبر Google'));
      }
      return const Right(unit);
    } on supabase.AuthException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  /// Sign out.
  Future<void> signOut() => _supabase.signOut();

  /// Stream of auth state changes.
  Stream<supabase.AuthState> get authStateChanges =>
      _supabase.authStateChanges;

  User _userFromAuth(supabase.User user) => User(
        id: UserId(user.id),
        email: user.email ?? '',
        role: UserRole.fromString(
          user.appMetadata['role'] as String? ?? 'student',
        ),
        fullName: user.userMetadata?['full_name'] as String?,
      );
}
