import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { redirect } from 'next/navigation'
import { createServerClient } from '@/lib/supabase-server'
import RegistrosClient from './RegistrosClient'

export const dynamic = 'force-dynamic'

export default async function RegistrosPage() {
  const session = await getServerSession(authOptions)
  if (!session?.user) redirect('/login')

  const supabase = createServerClient()

  const [reservasRes, soportesRes] = await Promise.all([
    supabase
      .from('reservas')
      .select(`
        id, fecha_desde, fecha_hasta, estado,
        clientes(id, nombre, empresa),
        reserva_items(
          id, soporte_id,
          soportes(id, nombre, tipo, es_digital)
        )
      `)
      .in('estado', ['aprobada', 'confirmada'])
      .order('fecha_desde', { ascending: false }),
    supabase
      .from('soportes')
      .select('id, nombre, tipo, es_digital')
      .eq('activo', true)
      .order('nombre'),
  ])

  return (
    <RegistrosClient
      reservas={(reservasRes.data ?? []) as unknown as Parameters<typeof RegistrosClient>[0]['reservas']}
      soportes={soportesRes.data ?? []}
      userId={session.user.id}
      userRol={session.user.rol}
      supabaseUrl={process.env.NEXT_PUBLIC_SUPABASE_URL!}
      supabaseAnonKey={process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!}
    />
  )
}
