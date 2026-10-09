-- ============================================================================
-- FamilyPrep: Idempotent RLS + Grants Alignment (safe to re-run)
-- Ensures remote Supabase matches recreate_all_tables.sql exactly, including
-- SECURITY DEFINER helpers, role coverage (authenticated/anon), and policies.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. SCHEMA GRANTS
-- ---------------------------------------------------------------------------
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT USAGE ON SCHEMA storage TO anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2. TABLE & SEQUENCE GRANTS (Explicit permissions for authenticated & anon)
-- ---------------------------------------------------------------------------
GRANT ALL ON public.estates TO authenticated;
GRANT ALL ON public.estate_access TO authenticated;
GRANT ALL ON public.documents TO authenticated;

GRANT SELECT ON public.estates TO anon;
GRANT SELECT ON public.estate_access TO anon;
GRANT SELECT ON public.documents TO anon;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. RLS ENABLEMENT (idempotent, no-op if already enabled)
-- ---------------------------------------------------------------------------
ALTER TABLE public.estates         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estate_access   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents       ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------------------
-- 4. SECURITY DEFINER HELPERS (SET row_security = off — breaks recursion)
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

-- ---------------------------------------------------------------------------
-- 5. DYNAMIC POLICY CLEANUP (Strips prior policies to avoid conflicts)
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

-- ---------------------------------------------------------------------------
-- 6. POLICIES: public.estates
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- 7. POLICIES: public.estate_access
-- ---------------------------------------------------------------------------
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
    USING (
        public.is_estate_owner(estate_id)
    )
    WITH CHECK (
        public.is_estate_owner(estate_id)
    );

CREATE POLICY estate_access_owner_delete ON public.estate_access
    FOR DELETE
    TO authenticated
    USING (
        public.is_estate_owner(estate_id)
    );

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

-- ---------------------------------------------------------------------------
-- 8. POLICIES: public.documents
-- ---------------------------------------------------------------------------
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
-- 9. STORAGE GRANTS (ensure bucket + storage policies)
-- ---------------------------------------------------------------------------
GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON storage.objects TO authenticated;
GRANT SELECT ON storage.objects TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA storage TO authenticated;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'estate-documents',
    'estate-documents',
    false,
    52428800,
    ARRAY['application/pdf','image/jpeg','image/png','image/heic','text/plain']
)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 10. STORAGE RLS POLICIES
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS estate_docs_select_linked ON storage.objects;
CREATE POLICY estate_docs_select_linked ON storage.objects
    FOR SELECT
    TO anon, authenticated
    USING (
        bucket_id = 'estate-documents'
        AND (storage.foldername(name))[1] = 'estate-documents'
        AND (storage.foldername(name))[2]::uuid IN (SELECT public.get_allowed_estate_ids())
    );

DROP POLICY IF EXISTS estate_docs_owner_list_on_storage ON storage.objects;
CREATE POLICY estate_docs_owner_list_on_storage ON storage.objects
    FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'estate-documents'
        AND (storage.foldername(name))[1] = 'estate-documents'
        AND (storage.foldername(name))[2]::uuid IN (SELECT public.get_allowed_estate_ids('owner'))
    );

DROP POLICY IF EXISTS estate_docs_insert_owner ON storage.objects;
CREATE POLICY estate_docs_insert_owner ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'estate-documents'
        AND (storage.foldername(name))[1] = 'estate-documents'
        AND (storage.foldername(name))[2]::uuid IN (SELECT public.get_allowed_estate_ids('owner'))
    );

DROP POLICY IF EXISTS estate_docs_update_owner ON storage.objects;
CREATE POLICY estate_docs_update_owner ON storage.objects
    FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'estate-documents'
        AND (storage.foldername(name))[1] = 'estate-documents'
        AND (storage.foldername(name))[2]::uuid IN (SELECT public.get_allowed_estate_ids('owner'))
    )
    WITH CHECK (
        bucket_id = 'estate-documents'
        AND (storage.foldername(name))[1] = 'estate-documents'
        AND (storage.foldername(name))[2]::uuid IN (SELECT public.get_allowed_estate_ids('owner'))
    );

DROP POLICY IF EXISTS estate_docs_delete_owner ON storage.objects;
CREATE POLICY estate_docs_delete_owner ON storage.objects
    FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'estate-documents'
        AND (storage.foldername(name))[1] = 'estate-documents'
        AND (storage.foldername(name))[2]::uuid IN (SELECT public.get_allowed_estate_ids('owner'))
    );
