/** @type {import("next").NextConfig} */
const nextConfig = {
  experimental: {
    // Remotion + Chromium son Node-only y traen binarios. No los puede bundlear webpack.
    serverComponentsExternalPackages: [
      '@remotion/bundler',
      '@remotion/renderer',
      'remotion',
      'esbuild',
      '@sparticuz/chromium-min',
    ],
    // Asegurar que las composiciones de Remotion (que se bundlean en runtime
    // con el bundler dentro de la API route) viajen al deploy serverless.
    outputFileTracingIncludes: {
      '/api/comprobantes': [
        // Bundle pre-armado en build (scripts/build-remotion.mjs) — evita correr
        // webpack en runtime durante el cold start.
        './.remotion-bundle/**/*',
        // Fallback por si el bundle pre-armado no está y hay que bundlear runtime.
        './src/remotion/**/*',
      ],
    },
  },
}
module.exports = nextConfig
