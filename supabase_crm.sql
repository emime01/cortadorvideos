-- ============================================================
-- CRM MOVIMAGEN — Schema completo
-- Ejecutar en: Supabase Dashboard > SQL Editor
-- Las tablas soportes, cotizaciones y cotizacion_items
-- ya existen — este script NO las modifica.
-- ============================================================

-- ============================================================
-- PERFILES (extiende auth.users)
-- ============================================================
CREATE TABLE IF NOT EXISTS perfiles (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  nombre               TEXT NOT NULL,
  rol                  TEXT NOT NULL CHECK (rol IN (
                         'vendedor','asistente_ventas','gerente_comercial',
                         'operaciones','arte','administracion'
                       )),
  porcentaje_comision  NUMERIC(5,2) DEFAULT 6.00,
  activo               BOOLEAN DEFAULT TRUE,
  created_at           TIMESTAMPTZ DEFAULT NOW(),
  updated_at           TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- CLIENTES
-- ============================================================
CREATE TABLE IF NOT EXISTS clientes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre      TEXT NOT NULL,
  empresa     TEXT,
  email       TEXT,
  telefono    TEXT,
  rut         TEXT,
  notas       TEXT,
  activo      BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- AGENCIAS
-- ============================================================
CREATE TABLE IF NOT EXISTS agencias (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre               TEXT NOT NULL,
  email                TEXT,
  telefono             TEXT,
  rut                  TEXT,
  ejecutivo_cuenta     TEXT,
  porcentaje_comision  NUMERIC(5,2) NOT NULL DEFAULT 0,
  incluye_produccion   BOOLEAN DEFAULT FALSE,
  notas                TEXT,
  activo               BOOLEAN DEFAULT TRUE,
  created_at           TIMESTAMPTZ DEFAULT NOW(),
  updated_at           TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ORDENES DE VENTA
-- ============================================================
CREATE TABLE IF NOT EXISTS ordenes_venta (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  numero               SERIAL UNIQUE,
  cotizacion_id        UUID REFERENCES cotizaciones(id),
  cliente_id           UUID REFERENCES clientes(id),
  agencia_id           UUID REFERENCES agencias(id),
  vendedor_id          UUID REFERENCES perfiles(id),
  compartida_con_id    UUID REFERENCES perfiles(id),
  facturar_a           TEXT NOT NULL DEFAULT 'cliente_final'
                         CHECK (facturar_a IN ('agencia','cliente_final')),

  -- Estado del flujo
  estado               TEXT NOT NULL DEFAULT 'borrador' CHECK (estado IN (
                         'borrador',
                         'pendiente_aprobacion',
                         'rechazada',
                         'aprobada',
                         'en_oic',
                         'facturada',
                         'cobrada'
                       )),

  -- Flags de tipo de entrega
  tiene_produccion     BOOLEAN DEFAULT FALSE,
  tiene_digital        BOOLEAN DEFAULT FALSE,

  -- Datos comerciales
  es_canje             BOOLEAN DEFAULT FALSE,
  incluir_reportes     BOOLEAN DEFAULT TRUE,
  es_mensualizada      BOOLEAN DEFAULT FALSE,
  monto_total          NUMERIC(12,2),
  monto_mensualizado   NUMERIC(12,2),
  moneda               TEXT DEFAULT 'USD' CHECK (moneda IN ('USD','UYU')),

  -- Condiciones de pago
  forma_pago_arrend    TEXT,
  comentario_arrend    TEXT,
  forma_pago_prod      TEXT,
  comentario_prod      TEXT,

  -- Fechas de campaña
  fecha_alta_prevista  DATE,
  fecha_baja_prevista  DATE,
  validez              DATE,
  referencia           TEXT,
  marca                TEXT,

  -- Aprobación / rechazo
  motivo_rechazo       TEXT,
  aprobado_por         UUID REFERENCES perfiles(id),
  aprobado_at          TIMESTAMPTZ,

  created_at           TIMESTAMPTZ DEFAULT NOW(),
  updated_at           TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ITEMS DE ORDEN
-- ============================================================
CREATE TABLE IF NOT EXISTS orden_items (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  orden_id             UUID NOT NULL REFERENCES ordenes_venta(id) ON DELETE CASCADE,
  soporte_id           UUID NOT NULL REFERENCES soportes(id),
  cantidad             INTEGER NOT NULL DEFAULT 1,
  semanas              INTEGER NOT NULL DEFAULT 1,
  salidas              INTEGER,
  segundos             INTEGER,
  precio_unitario      NUMERIC(12,2),
  descuento_pct        NUMERIC(5,2) DEFAULT 0,
  nota                 TEXT,

  -- Tipo de entrega
  requiere_grabado     BOOLEAN DEFAULT FALSE,
  requiere_produccion  BOOLEAN DEFAULT FALSE,

  -- Estado OIC
  estado_grabado       TEXT DEFAULT 'pendiente'
                         CHECK (estado_grabado IN ('pendiente','grabado')),
  estado_produccion    TEXT DEFAULT 'pendiente'
                         CHECK (estado_produccion IN (
                           'pendiente','en_produccion','producido','instalado'
                         )),
  numero_bus           TEXT,

  created_at           TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- BUSES
-- ============================================================
CREATE TABLE IF NOT EXISTS buses (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  numero                TEXT UNIQUE NOT NULL,
  modelo                TEXT,
  lado_disponible       TEXT DEFAULT 'ambos'
                          CHECK (lado_disponible IN ('izquierdo','derecho','ambos','ninguno')),
  orden_item_actual_id  UUID REFERENCES orden_items(id),
  cliente_actual_id     UUID REFERENCES clientes(id),
  fecha_baja_campana    DATE,
  notas                 TEXT,
  activo                BOOLEAN DEFAULT TRUE,
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- EVIDENCIAS (fotos y videos de campañas)
-- ============================================================
CREATE TABLE IF NOT EXISTS evidencias (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  orden_id         UUID NOT NULL REFERENCES ordenes_venta(id) ON DELETE CASCADE,
  orden_item_id    UUID REFERENCES orden_items(id),
  tipo             TEXT NOT NULL CHECK (tipo IN ('foto','video')),
  tipo_evidencia   TEXT CHECK (tipo_evidencia IN ('antes','instalacion','instalado','grabado')),
  url              TEXT NOT NULL,
  nombre_archivo   TEXT,
  subido_por       UUID REFERENCES perfiles(id),
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- PAGOS
-- ============================================================
CREATE TABLE IF NOT EXISTS pagos (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  orden_id         UUID NOT NULL REFERENCES ordenes_venta(id),
  monto            NUMERIC(12,2) NOT NULL,
  fecha_pago       DATE NOT NULL,
  metodo           TEXT,
  numero_factura   TEXT,
  notas            TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- COMISIONES VENDEDORES
-- ============================================================
CREATE TABLE IF NOT EXISTS comisiones (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pago_id          UUID NOT NULL REFERENCES pagos(id),
  vendedor_id      UUID NOT NULL REFERENCES perfiles(id),
  orden_id         UUID NOT NULL REFERENCES ordenes_venta(id),
  monto_base       NUMERIC(12,2) NOT NULL,
  porcentaje       NUMERIC(5,2) NOT NULL DEFAULT 6.00,
  monto_comision   NUMERIC(12,2) NOT NULL,
  liquidada        BOOLEAN DEFAULT FALSE,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- COMISIONES AGENCIAS
-- ============================================================
CREATE TABLE IF NOT EXISTS comisiones_agencia (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pago_id          UUID NOT NULL REFERENCES pagos(id),
  agencia_id       UUID NOT NULL REFERENCES agencias(id),
  orden_id         UUID NOT NULL REFERENCES ordenes_venta(id),
  monto_base       NUMERIC(12,2) NOT NULL,
  porcentaje       NUMERIC(5,2) NOT NULL,
  incluye_prod     BOOLEAN DEFAULT FALSE,
  monto_comision   NUMERIC(12,2) NOT NULL,
  liquidada        BOOLEAN DEFAULT FALSE,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- CANON
-- ============================================================
CREATE TABLE IF NOT EXISTS canon_config (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre       TEXT NOT NULL,
  porcentaje   NUMERIC(5,2) NOT NULL,
  activo       BOOLEAN DEFAULT TRUE,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS canon_soportes (
  canon_id    UUID REFERENCES canon_config(id) ON DELETE CASCADE,
  soporte_id  UUID REFERENCES soportes(id) ON DELETE CASCADE,
  PRIMARY KEY (canon_id, soporte_id)
);

CREATE TABLE IF NOT EXISTS canon_liquidaciones (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  canon_id     UUID NOT NULL REFERENCES canon_config(id),
  mes          INTEGER NOT NULL CHECK (mes BETWEEN 1 AND 12),
  anio         INTEGER NOT NULL,
  monto_base   NUMERIC(12,2) NOT NULL,
  porcentaje   NUMERIC(5,2) NOT NULL,
  monto_canon  NUMERIC(12,2) NOT NULL,
  pagado       BOOLEAN DEFAULT FALSE,
  fecha_pago   DATE,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- GASTOS DE TARJETA
-- ============================================================
CREATE TABLE IF NOT EXISTS gastos_tarjeta (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mes          INTEGER NOT NULL CHECK (mes BETWEEN 1 AND 12),
  anio         INTEGER NOT NULL,
  fecha        DATE NOT NULL,
  descripcion  TEXT NOT NULL,
  monto        NUMERIC(12,2) NOT NULL,
  categoria    TEXT,
  controlado   BOOLEAN DEFAULT FALSE,
  comentario   TEXT,
  orden_id     UUID REFERENCES ordenes_venta(id),
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- HISTORIAL DE ÓRDENES (auditoría)
-- ============================================================
CREATE TABLE IF NOT EXISTS orden_historial (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  orden_id         UUID NOT NULL REFERENCES ordenes_venta(id) ON DELETE CASCADE,
  perfil_id        UUID REFERENCES perfiles(id),
  estado_anterior  TEXT,
  estado_nuevo     TEXT,
  comentario       TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- LEADS
-- ============================================================
CREATE TABLE IF NOT EXISTS leads (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendedor_id       UUID NOT NULL REFERENCES perfiles(id),
  cliente_id        UUID REFERENCES clientes(id),
  agencia_id        UUID REFERENCES agencias(id),
  descripcion       TEXT,
  monto_potencial   NUMERIC(12,2),
  cuatrimestre      TEXT,
  estado            TEXT NOT NULL DEFAULT 'nuevo' CHECK (estado IN (
                      'nuevo','en_conversacion','propuesta_enviada',
                      'negociacion','ganado','perdido'
                    )),
  motivo_perdida    TEXT,
  reserva_id        UUID,
  notas             TEXT,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- REUNIONES
-- ============================================================
CREATE TABLE IF NOT EXISTS reuniones (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendedor_id              UUID NOT NULL REFERENCES perfiles(id),
  cliente_id               UUID REFERENCES clientes(id),
  agencia_id               UUID REFERENCES agencias(id),
  lead_id                  UUID REFERENCES leads(id),
  fecha                    TIMESTAMPTZ NOT NULL,
  tipo                     TEXT CHECK (tipo IN ('presencial','virtual','llamada','email')),
  participantes            TEXT,
  resumen                  TEXT,
  resultado                TEXT CHECK (resultado IN (
                             'positivo','neutral','negativo','sin_respuesta'
                           )),
  proximo_paso             TEXT,
  fecha_proximo_contacto   DATE,
  created_at               TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- OBJETIVOS POR CUATRIMESTRE
-- ============================================================
CREATE TABLE IF NOT EXISTS objetivos (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendedor_id      UUID NOT NULL REFERENCES perfiles(id),
  cuatrimestre     TEXT NOT NULL,
  objetivo_monto   NUMERIC(12,2) NOT NULL,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (vendedor_id, cuatrimestre)
);

CREATE TABLE IF NOT EXISTS potenciales_cliente (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendedor_id      UUID NOT NULL REFERENCES perfiles(id),
  cliente_id       UUID NOT NULL REFERENCES clientes(id),
  cuatrimestre     TEXT NOT NULL,
  monto_potencial  NUMERIC(12,2) NOT NULL,
  notas            TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (vendedor_id, cliente_id, cuatrimestre)
);

-- ============================================================
-- RESERVAS DE DISPONIBILIDAD
-- ============================================================
CREATE TABLE IF NOT EXISTS reservas (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  soporte_id    UUID NOT NULL REFERENCES soportes(id),
  lead_id       UUID REFERENCES leads(id),
  orden_id      UUID REFERENCES ordenes_venta(id),
  cliente_id    UUID NOT NULL REFERENCES clientes(id),
  vendedor_id   UUID NOT NULL REFERENCES perfiles(id),
  fecha_desde   DATE NOT NULL,
  fecha_hasta   DATE NOT NULL,
  estado        TEXT NOT NULL DEFAULT 'pendiente' CHECK (estado IN (
                  'pendiente','aprobada','rechazada','confirmada','vencida'
                )),
  aprobada_por  UUID REFERENCES perfiles(id),
  notas         TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- CONFIGURACIÓN GLOBAL
-- ============================================================
CREATE TABLE IF NOT EXISTS config (
  clave        TEXT PRIMARY KEY,
  valor        TEXT NOT NULL,
  tipo         TEXT DEFAULT 'text' CHECK (tipo IN ('text','number','boolean','json','list')),
  descripcion  TEXT,
  seccion      TEXT,
  updated_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_by   UUID REFERENCES perfiles(id)
);

-- Valores iniciales de configuración
INSERT INTO config (clave, valor, tipo, descripcion, seccion) VALUES
  ('comision_vendedor_pct',      '6',                                            'number', 'Porcentaje base de comisión para vendedores',            'comisiones'),
  ('formas_pago',                '["Contado","30 días","60 días","90 días"]',     'list',   'Formas de pago disponibles en el formulario de orden',   'facturacion'),
  ('monedas',                    '["USD","UYU"]',                                 'list',   'Monedas disponibles',                                    'facturacion'),
  ('dias_alerta_vencimiento',    '5',                                             'number', 'Días antes del vencimiento para alertar en facturación', 'facturacion'),
  ('dias_alerta_alta_prevista',  '7',                                             'number', 'Días de anticipación para alertas en OIC',               'oic'),
  ('categorias_gasto',           '["Viáticos","Insumos","Servicios","Entretenimiento","Otros"]', 'list', 'Categorías de gastos de tarjeta', 'gastos'),
  ('cuatrimestres',              '["Q1","Q2","Q3"]',                              'list',   'Cuatrimestres del año comercial',                        'general'),
  ('empresa_nombre',             'Movimagen',                                     'text',   'Nombre de la empresa',                                   'general'),
  ('empresa_rut',                '',                                              'text',   'RUT de la empresa para facturas',                        'general'),
  ('ia_provider',                'claude',                                        'text',   'Proveedor de IA: claude o gemini',                       'ia'),
  ('ia_model',                   'claude-sonnet-4-6',                             'text',   'Modelo de IA a utilizar',                                'ia')
ON CONFLICT (clave) DO NOTHING;

-- ============================================================
-- RLS — Row Level Security
-- ============================================================
ALTER TABLE perfiles            ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes            ENABLE ROW LEVEL SECURITY;
ALTER TABLE agencias            ENABLE ROW LEVEL SECURITY;
ALTER TABLE ordenes_venta       ENABLE ROW LEVEL SECURITY;
ALTER TABLE orden_items         ENABLE ROW LEVEL SECURITY;
ALTER TABLE buses               ENABLE ROW LEVEL SECURITY;
ALTER TABLE evidencias          ENABLE ROW LEVEL SECURITY;
ALTER TABLE pagos               ENABLE ROW LEVEL SECURITY;
ALTER TABLE comisiones          ENABLE ROW LEVEL SECURITY;
ALTER TABLE comisiones_agencia  ENABLE ROW LEVEL SECURITY;
ALTER TABLE canon_config        ENABLE ROW LEVEL SECURITY;
ALTER TABLE canon_soportes      ENABLE ROW LEVEL SECURITY;
ALTER TABLE canon_liquidaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE gastos_tarjeta      ENABLE ROW LEVEL SECURITY;
ALTER TABLE orden_historial     ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads               ENABLE ROW LEVEL SECURITY;
ALTER TABLE reuniones           ENABLE ROW LEVEL SECURITY;
ALTER TABLE objetivos           ENABLE ROW LEVEL SECURITY;
ALTER TABLE potenciales_cliente ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservas            ENABLE ROW LEVEL SECURITY;
ALTER TABLE config              ENABLE ROW LEVEL SECURITY;

-- Política base: usuarios autenticados ven todo (se refina por rol en la app)
-- En producción reemplazar por políticas más estrictas por rol
CREATE POLICY "authenticated_all" ON perfiles            FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON clientes            FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON agencias            FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON ordenes_venta       FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON orden_items         FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON buses               FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON evidencias          FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON pagos               FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON comisiones          FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON comisiones_agencia  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON canon_config        FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON canon_soportes      FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON canon_liquidaciones FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON gastos_tarjeta      FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON orden_historial     FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON leads               FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON reuniones           FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON objetivos           FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON potenciales_cliente FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON reservas            FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON config              FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ============================================================
-- VERIFICAR
-- ============================================================
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
