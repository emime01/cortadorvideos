# CRM Movimagen

Sistema de gestión comercial interno para Movimagen.

## Stack

- **Next.js 14** — frontend + API Routes
- **Supabase** — base de datos PostgreSQL + auth + storage
- **NextAuth.js** — sesiones y roles
- **Tailwind CSS** — estilos
- **Montserrat** — tipografía corporativa

---

## Setup inicial (paso a paso)

### 1. Clonar e instalar dependencias

```bash
git clone https://github.com/TU_ORG/crm-movimagen.git
cd crm-movimagen
npm install
```

### 2. Configurar variables de entorno

```bash
cp .env.example .env.local
```

Completar en `.env.local`:
- `NEXT_PUBLIC_SUPABASE_URL` — en Supabase > Settings > API
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` — en Supabase > Settings > API
- `SUPABASE_SERVICE_ROLE_KEY` — en Supabase > Settings > API (⚠️ nunca al frontend)
- `NEXTAUTH_SECRET` — generar con `openssl rand -base64 32`
- `ANTHROPIC_API_KEY` — en console.anthropic.com

### 3. Crear las tablas en Supabase

Ir a **Supabase Dashboard > SQL Editor** y ejecutar:

```
supabase_crm.sql
```

> Las tablas `soportes`, `cotizaciones` y `cotizacion_items` ya existen — el script no las modifica.

### 4. Crear el primer usuario

En **Supabase Dashboard > Authentication > Users**, crear un usuario con email y password.

Luego en **SQL Editor** crear su perfil:

```sql
INSERT INTO perfiles (user_id, nombre, rol)
VALUES (
  'UUID_DEL_USUARIO_CREADO',
  'Tu Nombre',
  'administracion'  -- primer usuario siempre admin
);
```

### 5. Correr en desarrollo

```bash
npm run dev
```

Abrir [http://localhost:3000](http://localhost:3000)

### 6. Deploy en Railway

1. Subir el repo a GitHub
2. En Railway: New Project > Deploy from GitHub repo
3. Agregar las variables de entorno del `.env.example`
4. Railway detecta Next.js automáticamente y despliega

---

## Estructura del proyecto

```
crm-movimagen/
├── src/
│   ├── app/
│   │   ├── api/
│   │   │   └── auth/[...nextauth]/    ← NextAuth
│   │   ├── (auth)/
│   │   │   └── login/                 ← Página de login
│   │   └── (dashboard)/
│   │       ├── layout.tsx             ← Sidebar + topbar
│   │       ├── page.tsx               ← Dashboard principal
│   │       ├── ventas/
│   │       ├── leads/
│   │       ├── oic/
│   │       ├── arte/
│   │       ├── admin/
│   │       ├── disponibilidad/
│   │       ├── gerente/
│   │       └── config/
│   ├── components/
│   │   ├── ui/                        ← Botones, inputs, badges, cards
│   │   ├── layout/                    ← Sidebar, Topbar, ChatIA
│   │   └── shared/                    ← Tablas, filtros, exportar Excel
│   ├── lib/
│   │   └── supabase.ts                ← Cliente Supabase
│   ├── hooks/                         ← useSession, usePermisos, etc.
│   ├── types/
│   │   └── index.ts                   ← Todos los tipos TypeScript
│   ├── styles/
│   │   └── globals.css                ← Design tokens Movimagen
│   └── middleware.ts                  ← Protección de rutas por rol
├── supabase_crm.sql                   ← Schema de base de datos
├── .env.example                       ← Template de variables de entorno
└── package.json
```

---

## Roles y permisos

| Rol | Acceso |
|-----|--------|
| `vendedor` | Dashboard, ventas propias, leads, reuniones, disponibilidad (ver) |
| `asistente_ventas` | Todo lo del vendedor + aprobar reservas + configurar objetivos |
| `gerente_comercial` | Todo + aprobar órdenes + dashboard CEO |
| `operaciones` | OIC + evidencias |
| `arte` | Planilla digital + muestras de color |
| `administracion` | Facturación + comisiones + config + todo |

---

## Cuatrimestres

El año comercial se divide en 3 cuatrimestres:
- **Q1**: enero — abril
- **Q2**: mayo — agosto  
- **Q3**: septiembre — diciembre
