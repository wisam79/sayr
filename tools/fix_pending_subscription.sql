-- تفعيل الاشتراك المعلق مباشرة (إذا كان الدفع تم يدوياً)
UPDATE subscriptions
SET status = 'active',
    updated_at = NOW()
WHERE id = 'a3d517d9-0765-477c-9192-95d202f01b19'
  AND status = 'pending';

-- تأكيد
SELECT id, status, route_id FROM subscriptions 
WHERE id = 'a3d517d9-0765-477c-9192-95d202f01b19';
