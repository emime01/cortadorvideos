-- Migration V2: multi-soporte reservations, client types, product fields
-- Run this in Supabase SQL editor

-- 1. Make soporte_id nullable on reservas (for multi-soporte support)
ALTER TABLE reservas ALTER COLUMN soporte_id DROP NOT NULL;

-- 2. Multi-soporte reserva items
CREATE TABLE IF NOT EXISTS reserva_items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reserva_id  UUID NOT NULL REFERENCES reservas(id) ON DELETE CASCADE,
  soporte_id  UUID NOT NULL REFERENCES soportes(id),
  cantidad    INTEGER NOT NULL DEFAULT 1,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Client types A/B/C/D for objective weighting
CREATE TABLE IF NOT EXISTS tipos_cliente (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre       TEXT NOT NULL UNIQUE,
  ponderacion  DECIMAL(5,2) NOT NULL DEFAULT 100,
  color        TEXT DEFAULT '#6b7280',
  descripcion  TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO tipos_cliente (nombre, ponderacion, color, descripcion) VALUES
  ('A', 100, '#15803d', 'Pondera 100% del potencial hacia el objetivo'),
  ('B', 33,  '#2563eb', 'Pondera 33% del potencial hacia el objetivo'),
  ('C', 1,   '#d97706', 'Pondera 1% del potencial hacia el objetivo'),
  ('D', 0,   '#9a9895', 'No pondera al objetivo')
ON CONFLICT (nombre) DO NOTHING;

-- 4. Add tipo_cliente to clientes
ALTER TABLE clientes ADD COLUMN IF NOT EXISTS tipo_cliente TEXT DEFAULT 'B'
  CHECK (tipo_cliente IN ('A','B','C','D'));

-- 5. Add product fields to soportes
ALTER TABLE soportes ADD COLUMN IF NOT EXISTS tiene_iva BOOLEAN DEFAULT FALSE;
ALTER TABLE soportes ADD COLUMN IF NOT EXISTS precio_semanal NUMERIC(12,2);

-- 6. Propuestas linked to leads
CREATE TABLE IF NOT EXISTS propuestas (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id     UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  vendedor_id UUID NOT NULL REFERENCES perfiles(id),
  titulo      TEXT,
  notas       TEXT,
  estado      TEXT DEFAULT 'borrador'
                CHECK (estado IN ('borrador','enviada','aceptada','rechazada')),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS propuesta_items (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  propuesta_id    UUID NOT NULL REFERENCES propuestas(id) ON DELETE CASCADE,
  soporte_id      UUID REFERENCES soportes(id),
  descripcion     TEXT,
  cantidad        INTEGER DEFAULT 1,
  semanas         INTEGER DEFAULT 1,
  precio_unitario NUMERIC(12,2),
  descuento_pct   DECIMAL(5,2) DEFAULT 0
);

-- Enable RLS
ALTER TABLE reserva_items   ENABLE ROW LEVEL SECURITY;
ALTER TABLE tipos_cliente   ENABLE ROW LEVEL SECURITY;
ALTER TABLE propuestas      ENABLE ROW LEVEL SECURITY;
ALTER TABLE propuesta_items ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='authenticated_all' AND tablename='reserva_items') THEN
    CREATE POLICY "authenticated_all" ON reserva_items FOR ALL TO authenticated USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='authenticated_all' AND tablename='tipos_cliente') THEN
    CREATE POLICY "authenticated_all" ON tipos_cliente FOR ALL TO authenticated USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='authenticated_all' AND tablename='propuestas') THEN
    CREATE POLICY "authenticated_all" ON propuestas FOR ALL TO authenticated USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='authenticated_all' AND tablename='propuesta_items') THEN
    CREATE POLICY "authenticated_all" ON propuesta_items FOR ALL TO authenticated USING (true);
  END IF;
END $$;
