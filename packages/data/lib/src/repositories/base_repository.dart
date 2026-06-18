import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:talker_flutter/talker_flutter.dart';

/// Base repository class that provides exception-guarding helpers to concrete repositories.
abstract class BaseRepository {
  /// Creates a [BaseRepository] with the given [talker] instance for logging.
  BaseRepository({required Talker talker}) : _talker = talker;

  final Talker _talker;

  /// The logger instance, accessible by subclasses for direct logging.
  @protected
  Talker get log => _talker;

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
        _talker.warning(
          'Network issue caught in repository',
          e,
          st,
        );
      } else {
        _talker.error(
          'Exception caught in repository',
          e,
          st,
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

    if (code == null) {
      return const ServerFailure(
        message: 'An unexpected database error occurred',
      );
    }

    return switch (code) {
      // 23505: unique_violation
      '23505' => const ValidationFailure(
          message: 'A duplicate record violation occurred.',
          errors: ['A duplicate record violation occurred.'],
        ),
      // 23503: foreign_key_violation
      '23503' => const ValidationFailure(
          message: 'Reference violation: A related record was not found.',
          errors: ['Reference violation: A related record was not found.'],
        ),
      // 42P01: undefined_table
      '42P01' => const ServerFailure(
          message: 'Database configuration error (table not found)',
        ),
      // 42501: insufficient_privilege (RLS violation)
      '42501' => const ForbiddenFailure(),
      // 23502: not_null_violation
      '23502' => const ValidationFailure(
          message: 'A required field is missing.',
          errors: ['A required field is missing.'],
        ),
      _ =>
        const ServerFailure(message: 'An unexpected database error occurred'),
    };
  }
}
