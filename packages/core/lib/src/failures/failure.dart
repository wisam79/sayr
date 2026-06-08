import 'package:equatable/equatable.dart';

/// Base class for all failures in the system.
///
/// A [Failure] is the typed error returned from a use case
/// or repository operation. UI layer maps these to user-facing messages.
sealed class Failure extends Equatable {
  const Failure({this.message});

  /// Human-readable message (in user's locale).
  final String? message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'Failure($message)';
}

/// Network connectivity error.
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'لا يوجد اتصال بالإنترنت'});
}

/// Server-side error (5xx, unexpected).
class ServerFailure extends Failure {
  const ServerFailure({super.message = 'خطأ في الخادم', this.statusCode});

  /// HTTP status code if available.
  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

/// Authentication error (401).
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message = 'غير مصرح'});
}

/// Authorization error (403) - user lacks permission.
class ForbiddenFailure extends Failure {
  const ForbiddenFailure({super.message = 'غير مسموح'});
}

/// Resource not found (404).
class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message = 'غير موجود', this.resource});

  /// Name of the resource that was not found.
  final String? resource;

  @override
  List<Object?> get props => [message, resource];
}

/// Validation error (422).
class ValidationFailure extends Failure {
  const ValidationFailure({
    super.message = 'بيانات غير صحيحة',
    this.errors = const <String>[],
  });

  /// List of field-level errors.
  final List<String> errors;

  @override
  List<Object?> get props => [message, errors];
}

/// Rate limit exceeded (429).
class RateLimitFailure extends Failure {
  const RateLimitFailure({
    super.message = 'تجاوزت الحد المسموح',
    this.retryAfter,
  });

  /// Seconds until retry is allowed.
  final int? retryAfter;

  @override
  List<Object?> get props => [message, retryAfter];
}

/// Cache/Local storage error.
class CacheFailure extends Failure {
  const CacheFailure({super.message = 'خطأ في التخزين المحلي'});
}

/// Domain-specific failure: business rule violation.
class BusinessRuleFailure extends Failure {
  const BusinessRuleFailure({required super.message});
}

/// State machine transition failure.
class InvalidStateTransitionFailure extends Failure {
  const InvalidStateTransitionFailure({
    super.message = 'انتقال حالة غير مسموح',
    this.from,
    this.event,
  });

  /// The current state.
  final String? from;

  /// The attempted event.
  final String? event;

  @override
  List<Object?> get props => [message, from, event];
}

/// Unknown error (catch-all).
class UnknownFailure extends Failure {
  const UnknownFailure({super.message = 'خطأ غير معروف'});
}
