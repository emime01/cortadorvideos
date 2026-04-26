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
      '/api/comprobantes': ['./src/remotion/**/*'],
    },
  },
}
module.exports = nextConfig
