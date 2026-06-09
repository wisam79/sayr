import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Base repository class that provides exception-guarding helpers to concrete repositories.
abstract class BaseRepository {
  final Logger _baseLogger = Logger();

  /// Executes an operation and catches any database, auth, or network exception,
  /// converting them into appropriate [Failure] instances.
  Future<Either<Failure, T>> guard<T>(
    Future<T> Function() operation, {
    Failure Function(Object)? errorMapper,
  }) async {
    try {
      final result = await operation();
      return Right(result);
    } catch (e, st) {
      if (e is Failure) {
        return Left(e);
      }
      if (e is SocketException || e is HttpException) {
        _baseLogger.w(
          'Network issue caught in repository',
          error: e,
          stackTrace: st,
        );
      } else {
        _baseLogger.e(
          'Exception caught in repository',
          error: e,
          stackTrace: st,
        );
      }
      if (errorMapper != null) {
        return Left(errorMapper(e));
      }
      return Left(mapException(e));
    }
  }

  /// Maps an exception to a [Failure] instance.
  Failure mapException(Object e) {
    if (e is supabase.AuthException) {
      return UnauthorizedFailure(message: e.message);
    }
    if (e is supabase.PostgrestException) {
      return _mapPostgrestException(e);
    }
    if (e is SocketException || e is HttpException) {
      return const NetworkFailure();
    }
    if (e is Failure) {
      return e;
    }
    return ServerFailure(message: e.toString());
  }

  Failure _mapPostgrestException(supabase.PostgrestException e) {
    final code = e.code;
    final message = e.message;

    if (code == null) {
      return ServerFailure(message: message);
    }

    return switch (code) {
      // 23505: unique_violation
      '23505' => ValidationFailure(message: message, errors: [message]),
      // 23503: foreign_key_violation
      '23503' => ValidationFailure(
          message: 'Reference violation: $message',
          errors: [message],
        ),
      // 42P01: undefined_table
      '42P01' => const ServerFailure(
          message: 'Database configuration error (table not found)',
        ),
      // 42501: insufficient_privilege (RLS violation)
      '42501' => const ForbiddenFailure(),
      // 23502: not_null_violation
      '23502' => ValidationFailure(
          message: 'Required field missing: $message',
          errors: [message],
        ),
      _ => ServerFailure(message: message),
    };
  }
}
