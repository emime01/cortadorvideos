import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { createServerClient } from '@/lib/supabase-server'

export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions)
  if (!session?.user) return NextResponse.json({ error: 'No autenticado' }, { status: 401 })

  const rol = session.user.rol
  const canApprove = ['asistente_ventas', 'gerente_comercial', 'administracion'].includes(rol)

  let body: { estado: string; comentario?: string }
  try { body = await req.json() } catch {
    return NextResponse.json({ error: 'Payload inválido' }, { status: 400 })
  }

  const VALID = ['aprobada', 'rechazada', 'pendiente', 'confirmada', 'vencida']
  if (!VALID.includes(body.estado)) {
    return NextResponse.json({ error: 'Estado inválido' }, { status: 400 })
  }

  // Only asistente+ can approve/reject
  if (['aprobada', 'rechazada'].includes(body.estado) && !canApprove) {
    return NextResponse.json({ error: 'Sin permisos para aprobar/rechazar' }, { status: 403 })
  }

  const supabase = createServerClient()

  const updates: Record<string, unknown> = {
    estado: body.estado,
    updated_at: new Date().toISOString(),
  }

  if (['aprobada', 'rechazada'].includes(body.estado)) {
    updates.aprobada_por = session.user.id
  }

  const { error } = await supabase
    .from('reservas')
    .update(updates)
    .eq('id', params.id)

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ ok: true })
}
