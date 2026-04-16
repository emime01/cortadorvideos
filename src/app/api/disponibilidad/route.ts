import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { createServerClient } from '@/lib/supabase-server'

export interface SoporteConEstado {
  id: string
  nombre: string
  tipo: string | null
  seccion: string | null
  ubicacion: string | null
  estado: 'libre' | 'reservado' | 'ocupado'
  cliente: string | null
  fechaDesde: string | null
  fechaHasta: string | null
}

export async function GET(req: NextRequest) {
  const session = await getServerSession(authOptions)
  if (!session?.user) return NextResponse.json({ error: 'No autenticado' }, { status: 401 })

  const { searchParams } = new URL(req.url)
  const fecha = searchParams.get('fecha') ?? new Date().toISOString().split('T')[0]

  const supabase = createServerClient()

  const [{ data: soportes }, { data: ordenes }, { data: reservas }] = await Promise.all([
    supabase
      .from('soportes')
      .select('id, nombre, tipo, seccion, ubicacion')
      .eq('activo', true)
      .order('seccion')
      .order('nombre'),
    supabase
      .from('ordenes_venta')
      .select('id, fecha_alta_prevista, fecha_baja_prevista, clientes(nombre, empresa), orden_items(soporte_id)')
      .in('estado', ['aprobada', 'en_oic', 'facturada', 'cobrada'])
      .not('fecha_alta_prevista', 'is', null)
      .lte('fecha_alta_prevista', fecha)
      .gte('fecha_baja_prevista', fecha),
    supabase
      .from('reservas')
      .select('id, soporte_id, fecha_desde, fecha_hasta, estado, clientes(nombre, empresa)')
      .in('estado', ['pendiente', 'aprobada', 'confirmada'])
      .lte('fecha_desde', fecha)
      .gte('fecha_hasta', fecha),
  ])

  // Build occupation map: soporteId → { estado, cliente, fechaDesde, fechaHasta }
  const ocupadoMap = new Map<string, { cliente: string; fechaDesde: string; fechaHasta: string }>()
  const reservadoMap = new Map<string, { cliente: string; fechaDesde: string; fechaHasta: string }>()

  ordenes?.forEach((ord: any) => {
    const cli = Array.isArray(ord.clientes) ? ord.clientes[0] : ord.clientes
    const clienteNombre = cli?.empresa ?? cli?.nombre ?? null
    ;(ord.orden_items ?? []).forEach((item: any) => {
      if (!item.soporte_id) return
      if (!ocupadoMap.has(item.soporte_id)) {
        ocupadoMap.set(item.soporte_id, {
          cliente: clienteNombre,
          fechaDesde: ord.fecha_alta_prevista,
          fechaHasta: ord.fecha_baja_prevista,
        })
      }
    })
  })

  reservas?.forEach((r: any) => {
    if (!r.soporte_id || ocupadoMap.has(r.soporte_id)) return
    if (reservadoMap.has(r.soporte_id)) return
    const cli = Array.isArray(r.clientes) ? r.clientes[0] : r.clientes
    reservadoMap.set(r.soporte_id, {
      cliente: cli?.empresa ?? cli?.nombre ?? null,
      fechaDesde: r.fecha_desde,
      fechaHasta: r.fecha_hasta,
    })
  })

  const result: SoporteConEstado[] = (soportes ?? []).map((s: any) => {
    if (ocupadoMap.has(s.id)) {
      const info = ocupadoMap.get(s.id)!
      return { id: s.id, nombre: s.nombre, tipo: s.tipo, seccion: s.seccion, ubicacion: s.ubicacion, estado: 'ocupado', cliente: info.cliente, fechaDesde: info.fechaDesde, fechaHasta: info.fechaHasta }
    }
    if (reservadoMap.has(s.id)) {
      const info = reservadoMap.get(s.id)!
      return { id: s.id, nombre: s.nombre, tipo: s.tipo, seccion: s.seccion, ubicacion: s.ubicacion, estado: 'reservado', cliente: info.cliente, fechaDesde: info.fechaDesde, fechaHasta: info.fechaHasta }
    }
    return { id: s.id, nombre: s.nombre, tipo: s.tipo, seccion: s.seccion, ubicacion: s.ubicacion, estado: 'libre', cliente: null, fechaDesde: null, fechaHasta: null }
  })

  return NextResponse.json({ soportes: result, fecha })
}
