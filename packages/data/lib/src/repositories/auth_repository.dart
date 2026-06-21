import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/datasources/local_datasource.dart';
import 'package:sayr_data/src/datasources/remote_datasource.dart';
import 'package:sayr_data/src/models/user_model.dart';
import 'package:sayr_data/src/repositories/base_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Concrete implementation of AuthRepository using Remote and Local data sources.
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl extends BaseRepository implements AuthRepository {
  AuthRepositoryImpl({
    required RemoteDatasource remoteDatasource,
    required LocalDatasource localDatasource,
    required super.talker,
  })  : _remoteDatasource = remoteDatasource,
        _localDatasource = localDatasource;
  final RemoteDatasource _remoteDatasource;
  final LocalDatasource _localDatasource;

  @override
  User? get currentUser {
    final authUser = _remoteDatasource.currentUser;
    if (authUser == null) return null;
    return UserModel.fromAuthUser(authUser).toEntity();
  }

  @override
  Future<Either<Failure, User>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return guard(() async {
      final response = await _remoteDatasource.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw const UnauthorizedFailure(message: 'login_failed');
      }
      final user = UserModel.fromAuthUser(response.user!).toEntity();
      await _localDatasource.setUserId(user.id.value);
      return user;
    });
  }

  @override
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    return guard(
      () async {
        final response = await _remoteDatasource.signUp(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
        );
        if (response.user == null) {
          throw const ValidationFailure(message: 'signup_failed');
        }
        final user = UserModel.fromAuthUser(response.user!).toEntity();
        await _localDatasource.setUserId(user.id.value);
        return user;
      },
      errorMapper: (e) {
        if (e is supabase.AuthException) {
          return ValidationFailure(message: e.message);
        }
        return mapException(e);
      },
    );
  }

  @override
  Future<Either<Failure, Unit>> signInWithGoogle() async {
    return guard(() async {
      final ok = await _remoteDatasource.signInWithGoogle();
      if (!ok) {
        throw const UnauthorizedFailure(message: 'google_signin_failed');
      }
      final user = _remoteDatasource.currentUser;
      if (user != null) {
        await _localDatasource.setUserId(user.id);
      }
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email) async {
    return guard(
      () async {
        await _remoteDatasource.sendPasswordResetEmail(email);
        return unit;
      },
      errorMapper: (e) {
        if (e is supabase.AuthException) {
          return ValidationFailure(message: e.message);
        }
        return mapException(e);
      },
    );
  }

  @override
  Future<Either<Failure, Unit>> updatePassword(String password) async {
    return guard(
      () async {
        await _remoteDatasource.updatePassword(password);
        return unit;
      },
      errorMapper: (e) {
        if (e is supabase.AuthException) {
          return ValidationFailure(message: e.message);
        }
        return mapException(e);
      },
    );
  }

  @override
  Future<void> signOut() async {
    // Deactivate push tokens on the server while still authenticated, so
    // the user stops receiving push notifications after logout.
    try {
      await _remoteDatasource.deactivatePushTokens();
    } catch (e) {
      // Best-effort — don't block logout if this fails.
      log.warning('Failed to deactivate push tokens during sign-out: $e');
    }
    await _localDatasource.clearSecureStorage();
    await _localDatasource.clearCachedTrips();
    await _remoteDatasource.signOut();
  }

  @override
  Stream<AuthStatus> get authStateChanges {
    return _remoteDatasource.authStateChanges.map((state) {
      if (state.session != null) {
        return AuthStatus.authenticated;
      }
      return AuthStatus.unauthenticated;
    });
  }

  @override
  Future<Either<Failure, Unit>> updateProfile({
    required String phone,
    required String institutionId,
  }) async {
    return guard(() async {
      final authUser = _remoteDatasource.currentUser;
      if (authUser == null) {
        throw const UnauthorizedFailure(message: 'user_not_logged_in');
      }
      await _remoteDatasource.updateProfile(
        phone: phone,
        institutionId: institutionId,
      );
      return unit;
    });
  }

  @override
  Future<Either<Failure, List<({String id, String name, String city})>>>
      getInstitutions() async {
    return guard(() async {
      final rows = await _remoteDatasource.getInstitutions();
      return rows.map((r) {
        return (
          id: r['id'] as String,
          name: r['name'] as String,
          city: r['city'] as String? ?? '',
        );
      }).toList();
    });
  }

  /// Fetches the full profile from `profiles` table and merges it with
  /// auth user data (email). Returns null if the profile doesn't exist yet.
  @override
  Future<User?> fetchFullProfile() async {
    final authUser = _remoteDatasource.currentUser;
    if (authUser == null) return null;
    final profile = await _remoteDatasource.fetchCurrentProfile(authUser.id);
    if (profile == null) return null;
    final model = profile.copyWith(email: authUser.email ?? '');
    return model.toEntity();
  }

  @override
  Failure mapException(Object e) {
    if (e is supabase.AuthException) {
      return UnauthorizedFailure(message: e.message);
    }
    if (e is Failure) {
      return e;
    }
    return UnknownFailure(message: e.toString());
  }
}
