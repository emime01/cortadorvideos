/** @type {import("next").NextConfig} */
const nextConfig = {
  experimental: {
    // Remotion usa esbuild, chromium y ffmpeg a nivel Node. No se puede bundlear.
    serverComponentsExternalPackages: [
      '@remotion/bundler',
      '@remotion/renderer',
      'remotion',
      'esbuild',
    ],
  },
}
module.exports = nextConfig
