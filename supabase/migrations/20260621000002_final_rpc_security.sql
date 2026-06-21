-- Migration: 20260621000002_final_rpc_security.sql
-- Description: Ensure all RPCs have SET search_path = public and REVOKE EXECUTE FROM PUBLIC.

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT p.oid::regprocedure AS func_sig, p.proname
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
    LOOP
        -- 1. Set search_path to public for security
        EXECUTE 'ALTER FUNCTION ' || r.func_sig || ' SET search_path = public';
        
        -- 2. Revoke execute from public to enforce explicit grants
        EXECUTE 'REVOKE EXECUTE ON FUNCTION ' || r.func_sig || ' FROM PUBLIC';

        -- 3. Grant execute to authenticated and service_role by default
        EXECUTE 'GRANT EXECUTE ON FUNCTION ' || r.func_sig || ' TO authenticated, service_role';
        
        -- 4. Specifically grant anon access to RLS helper functions
        IF r.proname IN ('is_admin', 'is_driver', 'get_my_role') THEN
            EXECUTE 'GRANT EXECUTE ON FUNCTION ' || r.func_sig || ' TO anon';
        END IF;
    END LOOP;
END $$;
