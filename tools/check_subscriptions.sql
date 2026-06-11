-- عرض كل الاشتراكات مع تفاصيلها
SELECT 
  s.id,
  s.student_id,
  p.full_name AS student_name,
  r.title AS route_title,
  s.status,
  s.start_date,
  s.end_date,
  s.created_at,
  l.code AS license_code
FROM subscriptions s
LEFT JOIN profiles p ON p.id = s.student_id
LEFT JOIN routes r ON r.id = s.route_id
LEFT JOIN licenses l ON l.id = s.license_id
ORDER BY s.created_at DESC;
