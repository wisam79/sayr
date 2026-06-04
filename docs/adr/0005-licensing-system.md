# ADR-0005: Atomic License & Seats Flow

## الحالة (Status)
**مقبول** - 2026-06-03

## السياق (Context)
في v1، نظام التراخيص (Licensing) له مشكلة P0:
> "Race condition in `complete_payment_and_activate_subscription`"
> "Seat is deducted before subscription is created; if INSERT fails, seat is lost and user paid without service"

نحتاج نظام تفعيل ذري (Atomic) مضمون.

## القرار (Decision)
نطبق **نفس الـ flow من v1** (المُحَسَّن) مع **3 طبقات حماية**:

### 1. Database-level (SQL)
```sql
-- داخل transaction واحد
BEGIN;
  -- 1. Lock license row
  SELECT * FROM licenses WHERE code = p_code AND status = 'active' 
    FOR UPDATE NOWAIT;
  
  -- 2. Verify route has seats
  UPDATE routes 
  SET available_seats = available_seats - 1 
  WHERE id = v_route_id AND available_seats > 0;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No seats available';
  END IF;
  
  -- 3. Mark license as used
  UPDATE licenses 
  SET status = 'used', used_by = p_user_id, used_at = NOW()
  WHERE id = v_license_id;
  
  -- 4. Create subscription
  INSERT INTO subscriptions (student_id, route_id, start_date, end_date, status)
  VALUES (p_user_id, v_route_id, NOW(), NOW() + INTERVAL '30 days', 'active');
  
  -- 5. Audit log
  INSERT INTO audit_logs (user_id, action, details)
  VALUES (p_user_id, 'license_activated', jsonb_build_object('license_id', v_license_id));
COMMIT;
```

### 2. Unique Constraint (Race Condition Prevention)
```sql
-- يمنع اشتراك نشط مزدوج لنفس (student, route)
CREATE UNIQUE INDEX idx_one_active_sub_per_route
ON subscriptions (student_id, route_id)
WHERE status IN ('active', 'pending');
```

### 3. Use Case Layer (Dart)
```dart
class ActivateLicenseUseCase {
  Future<Either<LicenseFailure, Subscription>> call({
    required LicenseCode code,
  }) async {
    // Pre-validation (client-side)
    if (!code.isValid) {
      return Left(InvalidLicenseCodeFailure());
    }
    
    // Network call to atomic RPC
    final result = await _repository.activateLicense(code);
    
    return result.fold(
      (failure) => Left(_mapFailure(failure)),
      (subscription) => Right(subscription),
    );
  }
  
  LicenseFailure _mapFailure(DataLayerFailure failure) {
    if (failure.code == 'no_seats') return NoSeatsAvailableFailure();
    if (failure.code == 'invalid_code') return InvalidLicenseCodeFailure();
    if (failure.code == 'already_used') return LicenseAlreadyUsedFailure();
    if (failure.code == 'duplicate_subscription') {
      return DuplicateSubscriptionFailure();
    }
    return UnknownFailure(failure.message);
  }
}
```

## الـ Flow الكامل
```
Admin: create_license_batch() → يُنشئ 100 code (8 chars)
     ↓
Student: activate_license("A1B2C3D4")
     ↓
RPC: update route.seats (-1) [atomic]
     ↓
RPC: update license.status = 'used' [atomic]
     ↓
RPC: insert subscription [atomic]
     ↓
RPC: insert audit_log [atomic]
     ↓
COMMIT (أو ROLLBACK)
```

## ضمانات (Guarantees)
- ✅ لا overbooking ممكن (DB-level check)
- ✅ لا seat loss ممكن (كل شيء في transaction واحد)
- ✅ لا duplicate subscription (unique index)
- ✅ Audit log كامل
- ✅ لا rollback خاطئ (NOWAIT + rollback كامل)

## Seats تتبع الاشتراك (ليس الرحلة)
- عند التفعيل: route.available_seats -= 1
- عند الإلغاء: route.available_seats += 1
- الطالب المشترك يركب أي رحلة تابعة لخطه

## المراجع
- [PostgreSQL Transactions](https://www.postgresql.org/docs/current/tutorial-transactions.html)
- [SELECT FOR UPDATE](https://www.postgresql.org/docs/current/sql-select.html#SQL-FOR-UPDATE-SHARE)
