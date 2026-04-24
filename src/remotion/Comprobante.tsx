import React from 'react'
import { AbsoluteFill, OffthreadVideo, Sequence, Img } from 'remotion'
import type { CalculateMetadataFunction } from 'remotion'
import { z } from 'zod'

export const FPS = 30
export const INTRO_SECONDS = 3
export const CLIP_SECONDS = 10
export const OUTRO_SECONDS = 3

export const comprobanteSchema = z.object({
  cliente: z.string(),
  logoUrl: z.string().nullable(),
  introUrl: z.string(),
  outroUrl: z.string(),
  fechaDesde: z.string(),
  fechaHasta: z.string(),
  clips: z.array(
    z.object({
      url: z.string(),
      soporteNombre: z.string(),
    }),
  ),
})

export type ComprobanteProps = z.infer<typeof comprobanteSchema>

export const calcMetadata: CalculateMetadataFunction<ComprobanteProps> = ({ props }) => {
  const totalSeconds = INTRO_SECONDS + props.clips.length * CLIP_SECONDS + OUTRO_SECONDS
  return {
    durationInFrames: totalSeconds * FPS,
    fps: FPS,
  }
}

function fmtDate(s: string): string {
  if (!s) return ''
  const d = new Date(s + 'T00:00:00')
  if (isNaN(d.getTime())) return s
  return d.toLocaleDateString('es-UY', { day: '2-digit', month: '2-digit', year: '2-digit' })
}

export const Comprobante: React.FC<ComprobanteProps> = ({
  logoUrl,
  introUrl,
  outroUrl,
  fechaDesde,
  fechaHasta,
  clips,
}) => {
  const introFrames = INTRO_SECONDS * FPS
  const clipFrames = CLIP_SECONDS * FPS
  const outroFrames = OUTRO_SECONDS * FPS
  const dateRange = `${fmtDate(fechaDesde)}  →  ${fmtDate(fechaHasta)}`

  return (
    <AbsoluteFill style={{ backgroundColor: '#000' }}>
      {/* INTRO: video fijo + logo del cliente */}
      <Sequence from={0} durationInFrames={introFrames}>
        <AbsoluteFill>
          <OffthreadVideo src={introUrl} muted />
          {logoUrl && (
            <AbsoluteFill
              style={{
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <div
                style={{
                  background: 'rgba(255,255,255,0.92)',
                  padding: 32,
                  borderRadius: 16,
                  boxShadow: '0 20px 60px rgba(0,0,0,0.35)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                <Img
                  src={logoUrl}
                  style={{
                    maxWidth: 480,
                    maxHeight: 280,
                    objectFit: 'contain',
                  }}
                />
              </div>
            </AbsoluteFill>
          )}
        </AbsoluteFill>
      </Sequence>

      {/* CLIPS: uno por soporte, con overlay de nombre + rango de fechas */}
      {clips.map((clip, i) => (
        <Sequence
          key={i}
          from={introFrames + i * clipFrames}
          durationInFrames={clipFrames}
        >
          <AbsoluteFill>
            <OffthreadVideo src={clip.url} muted />
            {/* Overlay inferior con texto */}
            <AbsoluteFill
              style={{
                justifyContent: 'flex-end',
              }}
            >
              <div
                style={{
                  background: 'linear-gradient(to top, rgba(0,0,0,0.75), rgba(0,0,0,0))',
                  padding: '60px 48px 36px 48px',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: 8,
                }}
              >
                <div
                  style={{
                    color: '#fff',
                    fontSize: 40,
                    fontWeight: 800,
                    fontFamily: 'sans-serif',
                    textShadow: '0 2px 8px rgba(0,0,0,0.6)',
                  }}
                >
                  {clip.soporteNombre}
                </div>
                <div
                  style={{
                    color: 'rgba(255,255,255,0.92)',
                    fontSize: 22,
                    fontWeight: 500,
                    fontFamily: 'sans-serif',
                    textShadow: '0 2px 6px rgba(0,0,0,0.6)',
                  }}
                >
                  {dateRange}
                </div>
              </div>
            </AbsoluteFill>
          </AbsoluteFill>
        </Sequence>
      ))}

      {/* OUTRO: video fijo */}
      <Sequence
        from={introFrames + clips.length * clipFrames}
        durationInFrames={outroFrames}
      >
        <AbsoluteFill>
          <OffthreadVideo src={outroUrl} muted />
        </AbsoluteFill>
      </Sequence>
    </AbsoluteFill>
  )
}
