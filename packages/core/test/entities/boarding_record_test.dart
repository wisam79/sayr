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

  BoardingRecord makeRecord({BoardingMethod? method, String? studentName}) {
    return BoardingRecord(
      id: const BoardingId('rec-1'),
      tripId: const TripId('trip-1'),
      subscriptionId: const SubscriptionId('sub-1'),
      studentId: const UserId('user-1'),
      studentName: studentName ?? 'Ahmed Ali',
      boardedAt: fixedNow,
      boardingMethod: method ?? BoardingMethod.qrScan,
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
  });

  group('BoardingRecord', () {
    test('boardingMethod is BoardingMethod.qrScan', () {
      final record = makeRecord(method: BoardingMethod.qrScan);
      expect(record.boardingMethod, BoardingMethod.qrScan);
    });

    test('boardingMethod is BoardingMethod.manual', () {
      final record = makeRecord(method: BoardingMethod.manual);
      expect(record.boardingMethod, BoardingMethod.manual);
    });

    test('boardingMethod is BoardingMethod.selfCheckIn', () {
      final record = makeRecord(method: BoardingMethod.selfCheckIn);
      expect(record.boardingMethod, BoardingMethod.selfCheckIn);
    });

    test('default boardingMethod is BoardingMethod.qrScan', () {
      final record = BoardingRecord(
        id: const BoardingId('rec-1'),
        tripId: const TripId('trip-1'),
        subscriptionId: const SubscriptionId('sub-1'),
        studentId: const UserId('user-1'),
        boardedAt: fixedNow,
      );
      expect(record.boardingMethod, BoardingMethod.qrScan);
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
  });

  group('BoardingMethod', () {
    test('has exactly 3 values', () {
      expect(BoardingMethod.values, hasLength(3));
    });
  });
}
