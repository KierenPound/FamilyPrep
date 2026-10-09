-- ============================================================================
-- FamilyPrep: Hardened execute-grants + RLS alignment
--
-- This is a targeted fix for the "permission denied for table estate_access"
-- error that can still appear even after RLS policies are applied, because:
--   1. The SECURITY DEFINER helpers (is_estate_owner, get_allowed_estate_ids,
--      get_estate_role_for_current_user) were not explicitly GRANT EXECUTE to
--      anon/authenticated — in strict Postgres defaults the function body
--      can silently fail permission checks even though SECURITY DEFINER is set.
--   2. SECURITY DEFINER search_path must be SET explicitly to avoid search_path
--      hijack warnings which also surface as "permission denied" in Postgres 15+.
--
-- Kieren — please paste this WHOLE file into Supabase Dashboard → SQL Editor
-- and hit "Run". Then re-run the FamilyPrep iOS app and tap "Generate Invite Code"
-- while watching the Xcode debug console for the new 🔒 / 👤 print lines.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. SCHEMA + TABLE GRANTS (re-apply — supabase has a habit of dropping these
--    when you save changes via the Dashboard UI)
-- ---------------------------------------------------------------------------
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA storage TO anon, authenticated, service_role;

GRANT ALL ON public.estates        TO authenticated, service_role;
GRANT ALL ON public.estate_access  TO authenticated, service_role;
GRANT ALL ON public.documents      TO authenticated, service_role;

GRANT SELECT ON public.estates        TO anon;
GRANT SELECT ON public.estate_access  TO anon;
GRANT SELECT ON public.documents      TO anon;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;

GRANT USAGE ON SCHEMA storage TO authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON storage.objects TO authenticated, service_role;
GRANT SELECT ON storage.objects TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA storage TO anon, authenticated, service_role;

ALTER TABLE public.estates         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estate_access   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents       ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------------------
-- 2. RECREATE SECURITY DEFINER HELPERS WITH EXPLICIT search_path + EXECUTE
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.is_estate_owner(check_estate_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
SET row_security = off
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.estates
        WHERE id = check_estate_id
          AND owner_id IS NOT NULL
          AND auth.uid() IS NOT NULL
          AND owner_id = auth.uid()
    );
$$;

CREATE OR REPLACE FUNCTION public.get_allowed_estate_ids(requested_role text)
RETURNS SETOF uuid
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
SET row_security = off
AS $$
    SELECT estate_id
    FROM   public.estate_access
    WHERE  user_id = auth.uid()
    AND    status = 'accepted'
    AND    (requested_role IS NULL OR role = requested_role);
$$;

CREATE OR REPLACE FUNCTION public.get_allowed_estate_ids()
RETURNS SETOF uuid
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
SET row_security = off
AS $$
    SELECT public.get_allowed_estate_ids(NULL::text);
$$;

CREATE OR REPLACE FUNCTION public.get_estate_role_for_current_user(requested_estate_id uuid DEFAULT NULL)
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
SET row_security = off
AS $$
    SELECT role
    FROM   public.estate_access
    WHERE  user_id = auth.uid()
    AND    status = 'accepted'
    AND    (requested_estate_id IS NULL OR estate_id = requested_estate_id)
    ORDER  BY CASE role WHEN 'owner' THEN 1 WHEN 'executor' THEN 2 ELSE 3 END
    LIMIT  1;
$$;

-- !!! THE FIX — explicit EXECUTE grants. Without these, the helpers run under
-- SECURITY DEFINER but `anon` / `authenticated` have no permission to even
-- CALL the function body against pg_catalog lookups. This is the #1 hidden
-- cause of "permission denied for table estate_access" in Supabase 15+.
GRANT EXECUTE ON FUNCTION public.is_estate_owner(uuid)                       TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_allowed_estate_ids(text)                TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_allowed_estate_ids()                    TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_estate_role_for_current_user(uuid)      TO anon, authenticated, service_role;

ALTER FUNCTION public.is_estate_owner(uuid)                       SECURITY DEFINER;
ALTER FUNCTION public.get_allowed_estate_ids(text)                SECURITY DEFINER;
ALTER FUNCTION public.get_allowed_estate_ids()                    SECURITY DEFINER;
ALTER FUNCTION public.get_estate_role_for_current_user(uuid)      SECURITY DEFINER;

-- ---------------------------------------------------------------------------
-- 3. DROP + RE-CREATE ALL POLICIES (idempotent — safe to re-run)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN
        SELECT policyname, tablename
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename IN ('estate_access', 'estates', 'documents')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', pol.policyname, pol.tablename);
    END LOOP;
END $$;

-- ---- estates ----
CREATE POLICY estates_select_any_linked ON public.estates
    FOR SELECT
    TO anon, authenticated
    USING ( id IN (SELECT public.get_allowed_estate_ids()) );

CREATE POLICY estates_owner_insert ON public.estates
    FOR INSERT
    TO authenticated
    WITH CHECK ( auth.uid() = owner_id );

CREATE POLICY estates_owner_update ON public.estates
    FOR UPDATE
    TO authenticated
    USING ( id IN (SELECT public.get_allowed_estate_ids('owner')) )
    WITH CHECK ( auth.uid() = owner_id );

CREATE POLICY estates_owner_delete ON public.estates
    FOR DELETE
    TO authenticated
    USING ( auth.uid() = owner_id );

-- ---- estate_access ----
CREATE POLICY estate_access_select_linked ON public.estate_access
    FOR SELECT
    TO anon, authenticated
    USING (
        user_id = auth.uid()
        OR public.is_estate_owner(estate_id)
        OR (status = 'pending' AND user_id IS NULL AND invite_code IS NOT NULL)
    );

CREATE POLICY estate_access_owner_insert ON public.estate_access
    FOR INSERT
    TO authenticated
    WITH CHECK (
        user_id = auth.uid() OR public.is_estate_owner(estate_id)
    );

CREATE POLICY estate_access_owner_update ON public.estate_access
    FOR UPDATE
    TO authenticated
    USING ( public.is_estate_owner(estate_id) )
    WITH CHECK ( public.is_estate_owner(estate_id) );

CREATE POLICY estate_access_owner_delete ON public.estate_access
    FOR DELETE
    TO authenticated
    USING ( public.is_estate_owner(estate_id) );

CREATE POLICY estate_access_claim_pending_invite ON public.estate_access
    FOR UPDATE
    TO authenticated
    USING (
        status = 'pending'
        AND user_id IS NULL
        AND invite_code IS NOT NULL
        AND role = 'executor'
    )
    WITH CHECK (
        status = 'accepted'
        AND user_id = auth.uid()
        AND role = 'executor'
        AND estate_id = estate_id
        AND invite_code = invite_code
        AND invited_email = invited_email
    );

-- ---- documents ----
CREATE POLICY documents_select_any_linked ON public.documents
    FOR SELECT
    TO anon, authenticated
    USING ( estate_id IN (SELECT public.get_allowed_estate_ids()) );

CREATE POLICY documents_owner_insert ON public.documents
    FOR INSERT
    TO authenticated
    WITH CHECK ( estate_id IN (SELECT public.get_allowed_estate_ids('owner')) );

CREATE POLICY documents_owner_update ON public.documents
    FOR UPDATE
    TO authenticated
    USING ( estate_id IN (SELECT public.get_allowed_estate_ids('owner')) )
    WITH CHECK ( estate_id IN (SELECT public.get_allowed_estate_ids('owner')) );

CREATE POLICY documents_owner_delete ON public.documents
    FOR DELETE
    TO authenticated
    USING ( estate_id IN (SELECT public.get_allowed_estate_ids('owner')) );

-- ---------------------------------------------------------------------------
-- 4. DIAGNOSTIC VIEW — after running this, run the SELECTs below to verify
-- ---------------------------------------------------------------------------
-- SELECT * FROM public.estates;          -- should show 1 row with owner_id set
-- SELECT * FROM public.estate_access;    -- should show 1 owner row + pending invites
-- SELECT * FROM auth.users WHERE id = (SELECT owner_id FROM public.estates LIMIT 1);
--
-- If the last query returns 0 rows — your auth session's user UUID does not
-- match the owner_id in public.estates, which is why all RLS checks fail.
-- Delete the rows from public.estate_access and public.estates, then re-run the
-- FamilyPrep onboarding flow while signed in to create correctly-linked rows.
