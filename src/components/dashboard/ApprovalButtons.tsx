'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import { CheckCircle, XCircle } from 'lucide-react'

interface Props {
  ordenId: string
  numero: string
}

export default function ApprovalButtons({ ordenId, numero }: Props) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [done, setDone] = useState<'aprobada' | 'rechazada' | null>(null)
  const [error, setError] = useState<string | null>(null)

  async function handleAction(estado: 'aprobada' | 'rechazada') {
    setError(null)
    const comentario = estado === 'aprobada'
      ? `Orden ${numero} aprobada por gerente`
      : `Orden ${numero} rechazada por gerente`

    const res = await fetch(`/api/ordenes/${ordenId}/estado`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ estado, comentario }),
    })

    if (!res.ok) {
      const data = await res.json().catch(() => ({}))
      setError(data.error ?? 'Error al actualizar')
      return
    }

    setDone(estado)
    startTransition(() => { router.refresh() })
  }

  if (done) {
    return (
      <span style={{
        fontSize: 11,
        fontWeight: 700,
        padding: '3px 8px',
        borderRadius: 5,
        background: done === 'aprobada' ? 'rgba(21,128,61,0.12)' : 'rgba(220,38,38,0.12)',
        color: done === 'aprobada' ? '#15803d' : '#dc2626',
      }}>
        {done === 'aprobada' ? 'Aprobada ✓' : 'Rechazada ✗'}
      </span>
    )
  }

  return (
    <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
      {error && <span style={{ fontSize: 10, color: '#dc2626' }}>{error}</span>}
      <button
        onClick={() => handleAction('aprobada')}
        disabled={isPending}
        style={{
          width: 30, height: 30, borderRadius: 6,
          border: '1px solid var(--green)', background: 'var(--green-pale)',
          cursor: isPending ? 'wait' : 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          opacity: isPending ? 0.6 : 1,
        }}
        title="Aprobar"
      >
        <CheckCircle size={14} color="var(--green)" />
      </button>
      <button
        onClick={() => handleAction('rechazada')}
        disabled={isPending}
        style={{
          width: 30, height: 30, borderRadius: 6,
          border: '1px solid var(--red)', background: 'var(--red-pale)',
          cursor: isPending ? 'wait' : 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          opacity: isPending ? 0.6 : 1,
        }}
        title="Rechazar"
      >
        <XCircle size={14} color="var(--red)" />
      </button>
    </div>
  )
}
