UPDATE auth.users
SET raw_app_meta_data = raw_app_meta_data || '{"role": "admin"}'::jsonb
WHERE email = 'admin@sayr.iq';

SELECT email, raw_app_meta_data
FROM auth.users
WHERE email = 'admin@sayr.iq';
