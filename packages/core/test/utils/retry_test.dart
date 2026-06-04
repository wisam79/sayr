import 'package:sayr_core/sayr_core.dart';
import 'package:test/test.dart';

void main() {
  group('retryWithBackoff - success cases', () {
    test('returns value on first success', () async {
      var calls = 0;
      final result = await retryWithBackoff<int>(
        () async {
          calls++;
          return 42;
        },
        options: const RetryOptions(maxRetries: 3),
      );
      expect(result, equals(42));
      expect(calls, equals(1));
    });

    test('retries on failure and eventually succeeds', () async {
      var calls = 0;
      final result = await retryWithBackoff<int>(
        () async {
          calls++;
          if (calls < 3) {
            throw Exception('fail');
          }
          return 42;
        },
        options: const RetryOptions(
          maxRetries: 5,
          baseDelayMs: 1,
          maxDelayMs: 10,
        ),
      );
      expect(result, equals(42));
      expect(calls, equals(3));
    });
  });

  group('retryWithBackoff - failure cases', () {
    test('throws after exhausting all retries', () async {
      var calls = 0;
      await expectLater(
        retryWithBackoff<int>(
          () async {
            calls++;
            throw Exception('always fail');
          },
          options: const RetryOptions(
            maxRetries: 2,
            baseDelayMs: 1,
            maxDelayMs: 10,
          ),
        ),
        throwsA(isA<Exception>()),
      );
      expect(calls, equals(3)); // 1 initial + 2 retries
    });

    test('does not retry when shouldRetry returns false', () async {
      var calls = 0;
      await expectLater(
        retryWithBackoff<int>(
          () async {
            calls++;
            throw Exception('do not retry');
          },
          options: RetryOptions(
            maxRetries: 3,
            shouldRetry: (e) => false,
          ),
        ),
        throwsA(isA<Exception>()),
      );
      expect(calls, equals(1));
    });
  });
}
