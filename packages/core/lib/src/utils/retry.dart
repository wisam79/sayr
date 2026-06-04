import 'dart:math' as math;

/// Exponential backoff with jitter for retrying operations.
///
/// `delay = min(baseDelayMs * 2^attempt + jitter, maxDelayMs)`
/// where `jitter` is a random integer in `[0, baseDelayMs)`.
class RetryOptions {
  const RetryOptions({
    this.maxRetries = 3,
    this.baseDelayMs = 500,
    this.maxDelayMs = 30000,
    this.shouldRetry,
  });

  /// Maximum number of retry attempts (default: 3)
  final int maxRetries;

  /// Base delay in milliseconds (default: 500)
  final int baseDelayMs;

  /// Maximum delay cap in milliseconds (default: 30000)
  final int maxDelayMs;

  /// Predicate to decide whether to retry on a given error.
  ///
  /// Return `true` to retry, `false` to throw immediately.
  /// Default: always retry.
  final bool Function(Object error)? shouldRetry;
}

/// Retries an async function with exponential backoff and random jitter.
///
/// Throws the last error if all retries are exhausted.
///
/// ```dart
/// final data = await retryWithBackoff(
///   () => api.fetchData(),
///   const RetryOptions(maxRetries: 5),
/// );
/// ```
Future<T> retryWithBackoff<T>(
  Future<T> Function() fn, {
  RetryOptions options = const RetryOptions(),
  math.Random? random,
}) async {
  final rng = random ?? math.Random();
  Object? lastError;
  // ignore: avoid_dynamic_calls
  StackTrace? lastStack;

  for (var attempt = 0; attempt <= options.maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error, stack) {
      lastError = error;
      lastStack = stack;

      if (options.shouldRetry != null && !options.shouldRetry!(error)) {
        rethrow;
      }
      if (attempt == options.maxRetries) break;

      final jitter = rng.nextInt(options.baseDelayMs);
      final delay = math
          .min(
            options.baseDelayMs * math.pow(2, attempt).toInt() + jitter,
            options.maxDelayMs,
          )
          .toInt();
      await Future<void>.delayed(Duration(milliseconds: delay));
    }
  }

  // ignore: only_throw_errors
  if (lastError != null) {
    throw _RetryException(lastError, lastStack);
  }
  throw StateError('retryWithBackoff: unexpected state');
}

class _RetryException implements Exception {
  _RetryException(this.error, this.stackTrace);
  final Object error;
  final StackTrace? stackTrace;

  @override
  String toString() => 'RetryException: $error';
}
