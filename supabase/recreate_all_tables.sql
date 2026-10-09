-- ============================================================================
-- FamilyPrep: Master Migration Script (RLS Recursion Fix)
-- Target: https://mpsygpgaakdtlgjzmbtr.supabase.co
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. EXTENSIONS & SCHEMA GRANTS
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT USAGE ON SCHEMA storage TO anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2. TABLES & COLUMN GUARANTEES
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.estates (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id    uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name        text NOT NULL DEFAULT 'My Estate',
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.estate_access (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    estate_id     uuid NOT NULL REFERENCES public.estates(id) ON DELETE CASCADE,
    user_id       uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    role          text NOT NULL CHECK (role IN ('owner', 'executor')),
    created_at    timestamptz NOT NULL DEFAULT now()
);

DO $$
BEGIN
    ALTER TABLE public.estate_access ALTER COLUMN user_id DROP NOT NULL;
EXCEPTION WHEN others THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE public.estate_access ADD COLUMN status text;
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE public.estate_access ADD COLUMN invited_email text;
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE public.estate_access ADD COLUMN invite_code char(6);
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;

UPDATE public.estate_access
   SET status = 'accepted'
 WHERE status IS NULL
   AND user_id IS NOT NULL;

ALTER TABLE public.estate_access 
    DROP CONSTRAINT IF EXISTS estate_access_status_check;

ALTER TABLE public.estate_access
    ADD CONSTRAINT estate_access_status_check
    CHECK (status IN ('pending', 'accepted', 'revoked'));

ALTER TABLE public.estate_access 
    DROP CONSTRAINT IF EXISTS estate_access_invite_code_unique;

ALTER TABLE public.estate_access
    ADD CONSTRAINT estate_access_invite_code_unique UNIQUE (invite_code);

CREATE TABLE IF NOT EXISTS public.documents (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    estate_id     uuid NOT NULL REFERENCES public.estates(id) ON DELETE CASCADE,
    title         text NOT NULL,
    storage_path  text NOT NULL,
    category      text,
    created_at    timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- 3. INDEXES
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_documents_estate_id ON public.documents(estate_id);
CREATE INDEX IF NOT EXISTS idx_documents_category ON public.documents(category);

DROP INDEX IF EXISTS public.estate_access_unique_user_per_estate;
DROP INDEX IF EXISTS public.estate_access_unique_user_per_estate_partial;
CREATE UNIQUE INDEX IF NOT EXISTS estate_access_unique_user_per_estate_partial
    ON public.estate_access (estate_id, user_id)
    WHERE user_id IS NOT NULL;

DROP INDEX IF EXISTS public.estate_access_unique_pending_email_per_estate;
CREATE UNIQUE INDEX IF NOT EXISTS estate_access_unique_pending_email_per_estate
    ON public.estate_access (estate_id, invited_email)
    WHERE status = 'pending' AND invited_email IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 4. TABLE-LEVEL GRANTS
-- ---------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON public.estates         TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.estate_access   TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.documents       TO authenticated;
GRANT SELECT                                 ON public.estates         TO anon;
GRANT SELECT                                 ON public.estate_access   TO anon;
GRANT SELECT                                 ON public.documents       TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- ---------------------------------------------------------------------------
-- 5. ROW LEVEL SECURITY (RLS) ENABLEMENT
-- ---------------------------------------------------------------------------
ALTER TABLE public.estates         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estate_access   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents       ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------------------
-- 6. SECURITY DEFINER HELPERS (With row_security = off)
-- ---------------------------------------------------------------------------

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
-- 7. POLICIES: public.estates
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS estates_select_any_linked ON public.estates;
CREATE POLICY estates_select_any_linked ON public.estates
    FOR SELECT
    TO anon, authenticated
    USING ( id IN (SELECT public.get_allowed_estate_ids()) );

DROP POLICY IF EXISTS estates_owner_insert ON public.estates;
CREATE POLICY estates_owner_insert ON public.estates
    FOR INSERT
    TO authenticated
    WITH CHECK ( auth.uid() = owner_id );

DROP POLICY IF EXISTS estates_owner_update ON public.estates;
CREATE POLICY estates_owner_update ON public.estates
    FOR UPDATE
    TO authenticated
    USING ( id IN (SELECT public.get_allowed_estate_ids('owner')) )
    WITH CHECK ( auth.uid() = owner_id );

DROP POLICY IF EXISTS estates_owner_delete ON public.estates;
CREATE POLICY estates_owner_delete ON public.estates
    FOR DELETE
    TO authenticated
    USING ( auth.uid() = owner_id );

-- ---------------------------------------------------------------------------
-- 8. POLICIES: public.estate_access
-- ZERO CROSS-TABLE LOOKUPS TO GUARANTEE NO RECURSION
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS estate_access_select_linked ON public.estate_access;
CREATE POLICY estate_access_select_linked ON public.estate_access
    FOR SELECT
    TO anon, authenticated
    USING (
        user_id = auth.uid()
        OR (status = 'pending' AND user_id IS NULL AND invite_code IS NOT NULL)
    );

DROP POLICY IF EXISTS estate_access_owner_insert ON public.estate_access;
CREATE POLICY estate_access_owner_insert ON public.estate_access
    FOR INSERT
    TO authenticated
    WITH CHECK (
        -- Allow self-insert for owner access row or when authorized
        user_id = auth.uid() OR estate_id IN (SELECT public.get_allowed_estate_ids('owner'))
    );

DROP POLICY IF EXISTS estate_access_owner_update ON public.estate_access;
CREATE POLICY estate_access_owner_update ON public.estate_access
    FOR UPDATE
    TO authenticated
    USING (
        estate_id IN (SELECT public.get_allowed_estate_ids('owner'))
    )
    WITH CHECK (
        estate_id IN (SELECT public.get_allowed_estate_ids('owner'))
    );

DROP POLICY IF EXISTS estate_access_owner_delete ON public.estate_access;
CREATE POLICY estate_access_owner_delete ON public.estate_access
    FOR DELETE
    TO authenticated
    USING (
        estate_id IN (SELECT public.get_allowed_estate_ids('owner'))
    );

DROP POLICY IF EXISTS estate_access_claim_pending_invite ON public.estate_access;
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
-- 9. POLICIES: public.documents
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS documents_select_any_linked ON public.documents;
CREATE POLICY documents_select_any_linked ON public.documents
    FOR SELECT
    TO anon, authenticated
    USING ( estate_id IN (SELECT public.get_allowed_estate_ids()) );

DROP POLICY IF EXISTS documents_owner_insert ON public.documents;
CREATE POLICY documents_owner_insert ON public.documents
    FOR INSERT
    TO authenticated
    WITH CHECK ( estate_id IN (SELECT public.get_allowed_estate_ids('owner')) );

DROP POLICY IF EXISTS documents_owner_update ON public.documents;
CREATE POLICY documents_owner_update ON public.documents
    FOR UPDATE
    TO authenticated
    USING ( estate_id IN (SELECT public.get_allowed_estate_ids('owner')) )
    WITH CHECK ( estate_id IN (SELECT public.get_allowed_estate_ids('owner')) );

DROP POLICY IF EXISTS documents_owner_delete ON public.documents;
CREATE POLICY documents_owner_delete ON public.documents
    FOR DELETE
    TO authenticated
    USING ( estate_id IN (SELECT public.get_allowed_estate_ids('owner')) );

-- ---------------------------------------------------------------------------
-- 10. STORAGE BUCKET & STORAGE POLICIES
-- ---------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'estate-documents',
    'estate-documents',
    false,
    52428800,
    ARRAY['application/pdf','image/jpeg','image/png','image/heic','text/plain']
)
ON CONFLICT (id) DO NOTHING;

GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON storage.objects TO authenticated;
GRANT SELECT ON storage.objects TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA storage TO authenticated;

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