-- Migration v5: Logo de cliente + buckets de assets para comprobante Remotion
-- Correr en Supabase SQL editor

-- ============================================================
-- 1. Columna logo_url en clientes
-- ============================================================
ALTER TABLE clientes
  ADD COLUMN IF NOT EXISTS logo_url TEXT;

-- ============================================================
-- 2. Storage bucket para logos de clientes (público)
-- ============================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'logos',
  'logos',
  true,
  5242880,  -- 5 MB
  ARRAY['image/png', 'image/jpeg', 'image/jpg', 'image/webp', 'image/svg+xml']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Policy: authenticated users pueden subir/leer/actualizar/borrar logos
DROP POLICY IF EXISTS "auth_all_logos" ON storage.objects;
CREATE POLICY "auth_all_logos" ON storage.objects
  FOR ALL TO authenticated
  USING (bucket_id = 'logos')
  WITH CHECK (bucket_id = 'logos');

-- ============================================================
-- 3. Storage bucket para assets fijos (intro/outro del comprobante)
-- ============================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'assets',
  'assets',
  true,
  52428800,  -- 50 MB
  ARRAY['video/mp4', 'video/quicktime', 'video/webm']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Policy: solo administracion/operaciones suben/modifican; todos los auth pueden leer
DROP POLICY IF EXISTS "auth_read_assets" ON storage.objects;
CREATE POLICY "auth_read_assets" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'assets');

DROP POLICY IF EXISTS "admin_write_assets" ON storage.objects;
CREATE POLICY "admin_write_assets" ON storage.objects
  FOR ALL TO authenticated
  USING (
    bucket_id = 'assets'
    AND EXISTS (
      SELECT 1 FROM perfiles
      WHERE perfiles.id = auth.uid()
        AND perfiles.rol IN ('administracion', 'operaciones')
    )
  )
  WITH CHECK (
    bucket_id = 'assets'
    AND EXISTS (
      SELECT 1 FROM perfiles
      WHERE perfiles.id = auth.uid()
        AND perfiles.rol IN ('administracion', 'operaciones')
    )
  );
