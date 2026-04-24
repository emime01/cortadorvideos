import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { redirect } from 'next/navigation'
import { createServerClient } from '@/lib/supabase-server'
import BusesClient from './BusesClient'

export const dynamic = 'force-dynamic'

export default async function BusesPage() {
  const session = await getServerSession(authOptions)
  if (!session?.user) redirect('/login')

  const supabase = createServerClient()

  const [busesRes, soportesRes, clientesRes, reservasRes] = await Promise.all([
    supabase
      .from('buses')
      .select('*, clientes!buses_cliente_actual_id_fkey(nombre, empresa)')
      .eq('activo', true)
      .order('numero'),
    supabase
      .from('soportes')
      .select('id, nombre, tipo, lado_bus, bus_id')
      .eq('activo', true)
      .order('nombre'),
    supabase
      .from('clientes')
      .select('id, nombre, empresa')
      .eq('activo', true)
      .order('nombre'),
    supabase
      .from('reservas')
      .select('id, numero_reserva, fecha_desde, fecha_hasta, estado, clientes(nombre, empresa), reserva_items(id, soporte_id, bus_id, soportes(nombre, tipo, bus_id, lado_bus))')
      .eq('estado', 'aprobada')
      .order('fecha_desde'),
  ])

  const soportes = soportesRes.data ?? []
  const buses = (busesRes.data ?? []).map((b: Record<string, unknown> & { id: string }) => ({
    ...b,
    soportes: soportes.filter(s => s.bus_id === b.id),
  }))
  const soportesSinAsignar = soportes.filter(s => !s.bus_id)

  const reservasData = (reservasRes.data ?? []) as unknown as Array<{
    reserva_items: { soportes: { tipo: string | null; bus_id: string | null } | null }[]
  }>
  const reservas = reservasData.filter(r =>
    r.reserva_items.some(it => it.soportes?.tipo === 'bus' || it.soportes?.bus_id)
  )

  return (
    <BusesClient
      initialBuses={buses as unknown as Parameters<typeof BusesClient>[0]['initialBuses']}
      initialSoportesSinAsignar={soportesSinAsignar}
      clientes={clientesRes.data ?? []}
      initialReservas={reservas as unknown as Parameters<typeof BusesClient>[0]['initialReservas']}
      userRol={session.user.rol}
    />
  )
}
