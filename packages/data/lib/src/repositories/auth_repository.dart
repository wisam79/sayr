import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/datasources/local_datasource.dart';
import 'package:sayr_data/src/datasources/remote_datasource.dart';
import 'package:sayr_data/src/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Concrete implementation of AuthRepository using Remote and Local data sources.
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required RemoteDatasource remoteDatasource,
    required LocalDatasource localDatasource,
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
    try {
      final response = await _remoteDatasource.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        return const Left(
          UnauthorizedFailure(message: 'بيانات الدخول غير صحيحة'),
        );
      }
      final user = UserModel.fromAuthUser(response.user!).toEntity();
      await _localDatasource.setUserId(user.id.value);
      return Right(user);
    } on supabase.AuthException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final response = await _remoteDatasource.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      if (response.user == null) {
        return const Left(ValidationFailure(message: 'فشل إنشاء الحساب'));
      }
      final user = UserModel.fromAuthUser(response.user!).toEntity();
      await _localDatasource.setUserId(user.id.value);
      return Right(user);
    } on supabase.AuthException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> signInWithGoogle() async {
    try {
      final ok = await _remoteDatasource.signInWithGoogle();
      if (!ok) {
        return const Left(
          UnauthorizedFailure(message: 'فشل تسجيل الدخول عبر Google'),
        );
      }
      final user = _remoteDatasource.currentUser;
      if (user != null) {
        await _localDatasource.setUserId(user.id);
      }
      return const Right(unit);
    } on supabase.AuthException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email) async {
    try {
      await _remoteDatasource.sendPasswordResetEmail(email);
      return const Right(unit);
    } on supabase.AuthException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updatePassword(String password) async {
    try {
      await _remoteDatasource.updatePassword(password);
      return const Right(unit);
    } on supabase.AuthException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<void> signOut() async {
    await _localDatasource.clearSecureStorage();
    await _localDatasource.clearCachedTrips();
    await _remoteDatasource.signOut();
  }

  @override
  Stream<dynamic> get authStateChanges => _remoteDatasource.authStateChanges;

  @override
  Future<Either<Failure, Unit>> updateProfile({
    required String phone,
    required String institutionId,
  }) async {
    try {
      final authUser = _remoteDatasource.currentUser;
      if (authUser == null) {
        return const Left(UnauthorizedFailure(message: 'المستخدم غير مسجّل'));
      }
      await _remoteDatasource.updateProfile(
        userId: authUser.id,
        phone: phone,
        institutionId: institutionId,
      );
      return const Right(unit);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<({String id, String name, String city})>>>
      getInstitutions() async {
    try {
      final rows = await _remoteDatasource.getInstitutions();
      final list = rows.map((r) {
        return (
          id: r['id'] as String,
          name: r['name'] as String,
          city: r['city'] as String? ?? '',
        );
      }).toList();
      return Right(list);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  /// Fetches the full profile from `profiles` table and merges it with
  /// auth user data (email). Returns null if the profile doesn't exist yet.
  Future<User?> fetchFullProfile() async {
    final authUser = _remoteDatasource.currentUser;
    if (authUser == null) return null;
    final profile = await _remoteDatasource.fetchCurrentProfile(authUser.id);
    if (profile == null) return null;
    final model = UserModel.fromJson({
      ...profile,
      'email': authUser.email ?? '',
    });
    return model.toEntity();
  }
}
