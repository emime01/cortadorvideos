import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { createServerClient } from '@/lib/supabase-server'

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions)
  if (!session?.user) return NextResponse.json({ error: 'No autenticado' }, { status: 401 })

  let body: {
    soporteId: string
    clienteId: string
    fechaDesde: string
    fechaHasta: string
    notas?: string
  }
  try { body = await req.json() } catch {
    return NextResponse.json({ error: 'Payload inválido' }, { status: 400 })
  }

  if (!body.soporteId || !body.clienteId || !body.fechaDesde || !body.fechaHasta) {
    return NextResponse.json({ error: 'Faltan campos requeridos' }, { status: 400 })
  }

  const supabase = createServerClient()

  const { data, error } = await supabase
    .from('reservas')
    .insert({
      soporte_id: body.soporteId,
      cliente_id: body.clienteId,
      vendedor_id: session.user.id,
      fecha_desde: body.fechaDesde,
      fecha_hasta: body.fechaHasta,
      notas: body.notas || null,
      estado: 'pendiente',
    })
    .select('id')
    .single()

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ id: data.id }, { status: 201 })
}
