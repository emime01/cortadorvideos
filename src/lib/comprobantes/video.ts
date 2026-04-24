import fs from 'fs/promises'
import path from 'path'
import os from 'os'
import { bundle } from '@remotion/bundler'
import { selectComposition, renderMedia } from '@remotion/renderer'
import type { ComprobanteProps } from '@/remotion/Comprobante'

export interface VideoClip {
  url: string
  soporteNombre: string
}

export interface VideoComprobante {
  cliente: string
  logoUrl: string | null
  introUrl: string
  outroUrl: string
  numeroCampana: string
  fechaDesde: string
  fechaHasta: string
  clips: VideoClip[]
}

let cachedBundle: string | null = null

async function getBundle(): Promise<string> {
  if (cachedBundle) return cachedBundle
  const entryPoint = path.resolve(process.cwd(), 'src/remotion/index.ts')
  cachedBundle = await bundle({
    entryPoint,
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    webpackOverride: (config: any) => config,
  })
  return cachedBundle
}

export async function generateVideoComprobante(data: VideoComprobante): Promise<Buffer> {
  const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'comprobante-'))
  const outputPath = path.join(tmpDir, 'output.mp4')

  try {
    const serveUrl = await getBundle()

    const inputProps: ComprobanteProps = {
      cliente: data.cliente,
      logoUrl: data.logoUrl,
      introUrl: data.introUrl,
      outroUrl: data.outroUrl,
      fechaDesde: data.fechaDesde,
      fechaHasta: data.fechaHasta,
      clips: data.clips,
    }

    const composition = await selectComposition({
      serveUrl,
      id: 'Comprobante',
      inputProps,
    })

    await renderMedia({
      composition,
      serveUrl,
      codec: 'h264',
      outputLocation: outputPath,
      inputProps,
      chromiumOptions: {
        // En Vercel/serverless, setear CHROMIUM_EXECUTABLE_PATH apuntando a
        // @sparticuz/chromium-min o similar. Localmente usa el Chrome del sistema.
      },
    })

    const buffer = await fs.readFile(outputPath)
    return buffer
  } finally {
    await fs.rm(tmpDir, { recursive: true, force: true })
  }
}
