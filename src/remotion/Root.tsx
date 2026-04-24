import React from 'react'
import { Composition } from 'remotion'
import { Comprobante, comprobanteSchema, calcMetadata, FPS, INTRO_SECONDS, CLIP_SECONDS, OUTRO_SECONDS } from './Comprobante'

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="Comprobante"
        component={Comprobante}
        // Dummy durationInFrames; real value is computed by calculateMetadata
        durationInFrames={(INTRO_SECONDS + CLIP_SECONDS + OUTRO_SECONDS) * FPS}
        fps={FPS}
        width={1280}
        height={720}
        schema={comprobanteSchema}
        calculateMetadata={calcMetadata}
        defaultProps={{
          cliente: 'Cliente',
          logoUrl: null,
          introUrl: '',
          outroUrl: '',
          fechaDesde: '',
          fechaHasta: '',
          clips: [{ url: '', soporteNombre: 'Soporte' }],
        }}
      />
    </>
  )
}
