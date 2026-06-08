import 'package:sayr_core/sayr_core.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.now();
  final fixedNow = DateTime(now.year, now.month, now.day, 8);

  BoardingToken makeToken({
    DateTime? issuedAt,
    DateTime? expiresAt,
    DateTime? consumedAt,
  }) {
    return BoardingToken(
      id: const BoardingTokenId('tok-1'),
      subscriptionId: const SubscriptionId('sub-1'),
      tripId: const TripId('trip-1'),
      studentId: const UserId('user-1'),
      tokenHash: 'hash-abc',
      issuedAt: issuedAt ?? DateTime.now().subtract(const Duration(seconds: 5)),
      expiresAt: expiresAt ?? DateTime.now().add(const Duration(seconds: 60)),
      consumedAt: consumedAt,
    );
  }

  BoardingRecord makeRecord({String? method, String? studentName}) {
    return BoardingRecord(
      id: const BoardingId('rec-1'),
      tripId: const TripId('trip-1'),
      subscriptionId: const SubscriptionId('sub-1'),
      studentId: const UserId('user-1'),
      studentName: studentName ?? 'Ahmed Ali',
      boardedAt: fixedNow,
      boardingMethod: method ?? 'qr_scan',
    );
  }

  group('BoardingToken', () {
    test('isValid is true when not consumed and not expired', () {
      final token = makeToken();
      expect(token.isValid, isTrue);
    });

    test('isValid is false when consumed', () {
      final token =
          makeToken(consumedAt: fixedNow.add(const Duration(seconds: 5)));
      expect(token.isValid, isFalse);
    });

    test('secondsUntilExpiry returns positive value for a fresh token', () {
      final token = makeToken(
        expiresAt: DateTime.now().add(const Duration(seconds: 42)),
      );
      expect(token.secondsUntilExpiry, inInclusiveRange(40, 42));
    });

    test('secondsUntilExpiry clamps at 0 for an expired token', () {
      final token = makeToken(
        expiresAt: DateTime.now().subtract(const Duration(seconds: 5)),
      );
      expect(token.secondsUntilExpiry, equals(0));
    });

    test('equality works for identical values', () {
      final issued = DateTime.now();
      final expiry = issued.add(const Duration(seconds: 60));
      final a = makeToken(issuedAt: issued, expiresAt: expiry);
      final b = makeToken(issuedAt: issued, expiresAt: expiry);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('fromJson/toJson round-trip preserves all fields', () {
      final original = makeToken();
      final json = original.toJson();
      final restored = BoardingToken.fromJson(json);
      expect(restored, equals(original));
    });
  });

  group('BoardingRecord', () {
    test('method parses qr_scan to BoardingMethod.qrScan', () {
      final record = makeRecord(method: 'qr_scan');
      expect(record.method, BoardingMethod.qrScan);
    });

    test('method parses manual to BoardingMethod.manual', () {
      final record = makeRecord(method: 'manual');
      expect(record.method, BoardingMethod.manual);
    });

    test('method parses self_check_in to BoardingMethod.selfCheckIn', () {
      final record = makeRecord(method: 'self_check_in');
      expect(record.method, BoardingMethod.selfCheckIn);
    });

    test('method falls back to qrScan for unknown string', () {
      final record = makeRecord(method: 'unknown_future_method');
      expect(record.method, BoardingMethod.qrScan);
    });

    test('default boardingMethod is qr_scan', () {
      final record = BoardingRecord(
        id: const BoardingId('rec-1'),
        tripId: const TripId('trip-1'),
        subscriptionId: const SubscriptionId('sub-1'),
        studentId: const UserId('user-1'),
        boardedAt: fixedNow,
      );
      expect(record.boardingMethod, equals('qr_scan'));
      expect(record.method, BoardingMethod.qrScan);
    });

    test('studentName is optional (nullable)', () {
      final record = BoardingRecord(
        id: const BoardingId('rec-1'),
        tripId: const TripId('trip-1'),
        subscriptionId: const SubscriptionId('sub-1'),
        studentId: const UserId('user-1'),
        boardedAt: fixedNow,
      );
      expect(record.studentName, isNull);
    });

    test('fromJson/toJson round-trip preserves all fields', () {
      final original = makeRecord();
      final json = original.toJson();
      final restored = BoardingRecord.fromJson(json);
      expect(restored, equals(original));
    });
  });

  group('BoardingMethod', () {
    test('has exactly 3 values', () {
      expect(BoardingMethod.values, hasLength(3));
    });
  });
}
